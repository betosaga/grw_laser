import 'dart:async';

/// The current robot protocol has no request IDs or correlated acknowledgements.
/// Observing a compatible response/state is NOT proof of command execution.
enum RobotCommandStatus {
  notSent,
  waiting,
  responseObserved,
  stateObserved,
  unknown,
}

class RobotCommandOutcome {
  final RobotCommandStatus status;
  final String reason;

  const RobotCommandOutcome(this.status, this.reason);
}

class RobotCommandReceipt {
  final int id;
  final int session;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final bool accepted;
  final Completer<RobotCommandOutcome> _completion = Completer();
  RobotCommandOutcome _outcome;

  RobotCommandReceipt({
    required this.id,
    required this.session,
    required this.payload,
    required this.createdAt,
    required this.accepted,
    required RobotCommandOutcome outcome,
  }) : _outcome = outcome {
    if (outcome.status != RobotCommandStatus.waiting) {
      _completion.complete(outcome);
    }
  }

  String get command => payload['f']?.toString().trim().toUpperCase() ?? '';
  RobotCommandOutcome get outcome => _outcome;
  Future<RobotCommandOutcome> get completed => _completion.future;

  void finish(RobotCommandOutcome outcome) {
    if (_completion.isCompleted) return;
    _outcome = outcome;
    _completion.complete(outcome);
  }

  /// Only existing protocol messages are used; no invented ACKs or probes.
  RobotCommandStatus? observationFor(Map<String, dynamic> message) {
    final function = message['f']?.toString().trim().toUpperCase();
    if (function == 'ROBOTSTATUS') {
      final status = message['status']?.toString().trim().toUpperCase();
      final target = const <String, Set<String>>{
            'PAUSE': {'PAUSE', 'PAUSED'},
            'WELD': {'WELDING', 'START', 'RUNNING'},
            'RESUME': {'WELDING', 'START', 'RUNNING'},
            'STOPCORDONE': {'END', 'INACTIVE', 'DONE', 'FINISHED'},
          }[command] ??
          const <String>{};
      if (target.contains(status)) return RobotCommandStatus.stateObserved;
      if (command == 'SETMODE' &&
          message['Status']?.toString().toUpperCase() == 'HOMEREACH') {
        return RobotCommandStatus.stateObserved;
      }
    }
    if (command == 'ARMPOSITION' &&
        function == 'ARMPOSITIONSTATUS' &&
        message['Status'] == payload['p']) {
      return RobotCommandStatus.stateObserved;
    }
    final movementCommands = const {
      'MOVE',
      'MOVERX',
      'MOVETO',
      'CENTERTORCH',
      'GOTOSAFEPOSITION',
      'PULIZIAMODE',
      'MAINTENANCEMODEDX',
      'MAINTENANCEMODESX',
      'TRANSPORTMODEDX',
      'TRANSPORTMODESX',
    };
    final compatible = (command == 'SETPOINT' &&
            function == 'GETPOINT' &&
            message['Point'] is Map) ||
        (command == 'SETSAFEPOSITION' &&
            function == 'SAFEPOSITION' &&
            message['coords'] != null) ||
        (command == 'RESETSAFEPOSITION' && function == 'RESETSAFEPOSITION') ||
        (command == 'SETUPAREA' &&
            function == 'FRAMESET' &&
            (int.tryParse('${message['Status']}') ?? 0) > 0) ||
        (movementCommands.contains(command) &&
            function == 'MOVEMENT' &&
            message['Status'] != null);
    return compatible ? RobotCommandStatus.responseObserved : null;
  }
}
