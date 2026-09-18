import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'robot_command.dart';
import 'robot_json_buffer.dart';

typedef RobotSocketConnector = Future<Socket> Function(
    String host, int port, Duration timeout);

enum RobotConnectionState { disconnected, connecting, awaitingData, online }

/// One owner for the TCP connection. Writes are never replayed or queued across
/// sessions. Protocol dispatch is synchronous and ordered; UI work runs apart.
/// Missing or slow telemetry never closes an established socket.
class RobotConnection {
  RobotConnection({
    required this.onMessage,
    required this.onStateChanged,
    required this.onCommandChanged,
    required this.onLog,
    RobotSocketConnector? connector,
    DateTime Function()? now,
    this.port = 20002,
    this.connectTimeout = const Duration(seconds: 5),
    this.reconnectInterval = const Duration(seconds: 5),
    this.commandTimeout = const Duration(seconds: 15),
  })  : _connector = connector ?? _connectSocket,
        _now = now ?? DateTime.now;

  final void Function(Map<String, dynamic>) onMessage;
  final void Function(RobotConnectionState, String) onStateChanged;
  final void Function(RobotCommandReceipt) onCommandChanged;
  final void Function(String) onLog;
  final RobotSocketConnector _connector;
  final DateTime Function() _now;
  final int port;
  final Duration connectTimeout;
  final Duration reconnectInterval;
  final Duration commandTimeout;

  Socket? _socket;
  StreamSubscription<String>? _subscription;
  Future<void>? _connecting;
  Timer? _reconnectTimer;
  final Set<Timer> _sessionTimers = {};
  final Map<int, RobotCommandReceipt> _pending = {};
  final Map<int, Timer> _commandTimers = {};
  Future<void> _uiWork = Future.value();
  bool _disposed = false;
  int _session = 0;
  int _nextCommand = 0;
  String _host = '';
  RobotConnectionState _state = RobotConnectionState.disconnected;

  Socket? get socket => _socket;
  int get session => _session;
  RobotConnectionState get state => _state;
  bool get isConnecting => _connecting != null;
  bool get isReconnecting => _reconnectTimer != null;
  bool isCurrentSession(int value) => !_disposed && value == _session;

  static Future<Socket> _connectSocket(
    String host,
    int port,
    Duration timeout,
  ) =>
      Socket.connect(host, port, timeout: timeout);

  void startReconnecting(String host) {
    if (_disposed) return;
    _setHost(host);
    _reconnectTimer ??= Timer.periodic(reconnectInterval, (_) {
      if (_socket == null && _connecting == null) unawaited(connect(_host));
    });
  }

  void stopReconnecting() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _setHost(String host) {
    if (_host != host && (_socket != null || _connecting != null)) {
      disconnect(reason: 'Indirizzo robot cambiato');
    }
    _host = host;
  }

  Future<void> connect(String host) {
    if (_disposed) return Future.value();
    _setHost(host);
    if (_connecting != null) return _connecting!;
    if (_socket != null) return Future.value();
    final epoch = ++_session;
    final attempt = _open(host, epoch);
    _connecting = attempt;
    return attempt.whenComplete(() {
      if (identical(_connecting, attempt)) _connecting = null;
    });
  }

  Future<void> _open(String host, int epoch) async {
    _setState(RobotConnectionState.connecting, 'Connessione a $host:$port');
    try {
      final candidate = await _connector(host, port, connectTimeout);
      // Install the output error handler before setup or destruction, including
      // sockets returned by an obsolete connection attempt.
      unawaited(
        candidate.done.then<void>(
          (_) {},
          onError: (Object e, StackTrace s) {
            onLog('[TCP OUTPUT session=$epoch] Errore gestito: $e\n$s');
            if (isCurrentSession(epoch) && identical(_socket, candidate)) {
              disconnect(reason: 'Errore invio TCP: $e');
            }
          },
        ),
      );
      if (!isCurrentSession(epoch)) {
        _destroySocket(candidate, epoch);
        return;
      }
      _socket = candidate;
      candidate.setOption(SocketOption.tcpNoDelay, true);
      final buffer = RobotJsonBuffer();
      _subscription =
          candidate.cast<List<int>>().transform(utf8.decoder).listen(
        (chunk) {
          if (!isCurrentSession(epoch)) return;
          try {
            for (final raw in buffer.add(chunk)) {
              if (!isCurrentSession(epoch)) break;
              _receive(raw, epoch);
            }
          } catch (e, s) {
            onLog('[RX session=$epoch] $e\n$s');
            disconnect(reason: 'Flusso robot non valido: $e');
          }
        },
        onDone: () {
          if (isCurrentSession(epoch)) disconnect(reason: 'Robot disconnesso');
        },
        onError: (Object e, StackTrace s) {
          if (isCurrentSession(epoch)) {
            onLog('[TCP INPUT session=$epoch] Errore gestito: $e\n$s');
            disconnect(reason: 'Errore ricezione TCP: $e');
          }
        },
        cancelOnError: true,
      );
      _setState(
        RobotConnectionState.awaitingData,
        'TCP aperto, in attesa del robot',
      );
    } catch (e, s) {
      if (!isCurrentSession(epoch)) return;
      onLog('[CONNECT session=$epoch] Errore gestito: $e\n$s');
      disconnect(reason: 'Connessione fallita: $e');
    }
  }

  void _receive(String raw, int epoch) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['MSG'] is! Map) {
        throw const FormatException('Oggetto MSG mancante');
      }
      final message = Map<String, dynamic>.from(decoded['MSG'] as Map);
      final function = message['f'];
      if (function is! String || function.trim().isEmpty) {
        throw const FormatException('Funzione MSG.f mancante');
      }
      if (_state != RobotConnectionState.online) {
        _setState(RobotConnectionState.online, 'Ricezione robot attiva');
      }
      _observeCommands(message);
      // No awaited delays here: state updates keep the TCP message order.
      onMessage(decoded);
    } catch (e, s) {
      onLog('[RX session=$epoch] Errore elaborazione: $e; payload=$raw\n$s');
    }
  }

  RobotCommandReceipt send(
    Map<String, dynamic> payload, {
    int? expectedSession,
  }) {
    final current = _socket;
    String encoded;
    try {
      encoded = jsonEncode(payload);
    } catch (e) {
      return reject(payload, 'Comando non serializzabile: $e');
    }
    if (payload['f'] is! String || (payload['f'] as String).trim().isEmpty) {
      return reject(payload, 'Comando senza funzione');
    }
    if (current == null ||
        _disposed ||
        (expectedSession != null && !isCurrentSession(expectedSession))) {
      return reject(payload, 'Connessione assente o sessione terminata');
    }
    // Bound tracking memory, without blocking STOP/OFF behind older commands.
    // There is no outbound replay queue.
    if (_pending.length >= 256) {
      _finish(
        _pending.values.first,
        const RobotCommandOutcome(
          RobotCommandStatus.unknown,
          'Limite monitoraggio raggiunto: esecuzione sconosciuta. Comando non reinviato',
        ),
      );
    }
    final receipt = RobotCommandReceipt(
      id: ++_nextCommand,
      session: _session,
      payload: Map<String, dynamic>.unmodifiable(payload),
      createdAt: _now(),
      accepted: true,
      outcome: const RobotCommandOutcome(
        RobotCommandStatus.waiting,
        'Affidato al socket; in attesa di risposta, esecuzione non confermata',
      ),
    );
    _pending[receipt.id] = receipt;
    _commandTimers[receipt.id] = Timer(commandTimeout, () {
      // A missing reply changes only the command outcome, never the TCP session.
      _finish(
        receipt,
        const RobotCommandOutcome(
          RobotCommandStatus.unknown,
          'Timeout: esecuzione sconosciuta. Comando non reinviato',
        ),
      );
    });
    try {
      current.write(encoded);
      _notifyCommandChanged(receipt);
    } catch (e) {
      // Once write is attempted, do not assert that zero bytes were sent.
      disconnect(reason: 'Errore scrittura TCP: $e');
    }
    return receipt;
  }

  RobotCommandReceipt reject(Map<String, dynamic> payload, String reason) {
    final receipt = RobotCommandReceipt(
      id: ++_nextCommand,
      session: _session,
      payload: Map<String, dynamic>.unmodifiable(payload),
      createdAt: _now(),
      accepted: false,
      outcome: RobotCommandOutcome(RobotCommandStatus.notSent, reason),
    );
    _notifyCommandChanged(receipt);
    return receipt;
  }

  void _observeCommands(Map<String, dynamic> message) {
    final matches = _pending.values
        .where((r) => r.observationFor(message) != null)
        .toList();
    // Even one compatible response is only an observation, never a correlated
    // ACK. With multiple candidates, do not arbitrarily choose a command.
    if (matches.length != 1) return;
    final receipt = matches.single;
    final status = receipt.observationFor(message)!;
    _finish(
      receipt,
      RobotCommandOutcome(
        status,
        status == RobotCommandStatus.stateObserved
            ? 'Stato atteso osservato; non è una conferma correlata al comando'
            : 'Risposta compatibile ricevuta; protocollo senza ID di conferma',
      ),
    );
  }

  void _finish(RobotCommandReceipt receipt, RobotCommandOutcome outcome) {
    if (_pending.remove(receipt.id) == null) return;
    _commandTimers.remove(receipt.id)?.cancel();
    receipt.finish(outcome);
    _notifyCommandChanged(receipt);
  }

  void _notifyCommandChanged(RobotCommandReceipt receipt) {
    try {
      onCommandChanged(receipt);
    } catch (e, s) {
      onLog(
        '[COMMAND CALLBACK session=${receipt.session}] Errore gestito: $e\n$s',
      );
    }
  }

  /// Own errors from async protocol side effects instead of leaving unawaited
  /// futures to the Flutter error zone. State changes before the first await
  /// still happen in message order.
  void runAction(FutureOr<void> Function() action) {
    unawaited(_runAction(action, _session));
  }

  Future<void> _runAction(FutureOr<void> Function() action, int epoch) async {
    if (!isCurrentSession(epoch)) return;
    try {
      await action();
    } catch (e, s) {
      onLog('[ACTION session=$epoch] Errore gestito: $e\n$s');
    }
  }

  /// Delayed protocol actions (e.g. SETMODE after listening) die with a session.
  void schedule(Duration delay, FutureOr<void> Function() action) {
    if (_socket == null || _disposed) return;
    final epoch = _session;
    late Timer timer;
    timer = Timer(delay, () {
      _sessionTimers.remove(timer);
      if (!isCurrentSession(epoch)) return;
      unawaited(_runAction(action, epoch));
    });
    _sessionTimers.add(timer);
  }

  /// Keep webview side effects ordered without delaying protocol processing.
  /// Work already executing cannot be undone; queued obsolete work is skipped.
  void enqueueUiWork(Future<void> Function() action) {
    final epoch = _session;
    _uiWork = _uiWork.then((_) async {
      if (!isCurrentSession(epoch)) return;
      try {
        await action();
      } catch (e, s) {
        if (isCurrentSession(epoch)) onLog('[UI session=$epoch] $e\n$s');
      }
    });
  }

  void disconnect({String reason = 'Connessione chiusa'}) {
    final epoch = _session;
    ++_session; // Invalidates connect futures, callbacks and delayed work first.
    for (final timer in _sessionTimers) {
      timer.cancel();
    }
    _sessionTimers.clear();
    _uiWork = Future.value();
    final subscription = _subscription;
    final current = _socket;
    _subscription = null;
    _socket = null;
    if (subscription != null)
      unawaited(_cancelSubscription(subscription, epoch));
    if (current != null) _destroySocket(current, epoch);
    for (final receipt in _pending.values.toList()) {
      _finish(
        receipt,
        RobotCommandOutcome(
          RobotCommandStatus.unknown,
          '$reason: esecuzione sconosciuta. Comando non reinviato',
        ),
      );
    }
    _setState(RobotConnectionState.disconnected, reason);
  }

  void _setState(RobotConnectionState state, String reason) {
    _state = state;
    onLog('[CONNECTION session=$_session] ${state.name}: $reason');
    try {
      onStateChanged(state, reason);
    } catch (e, s) {
      onLog('[STATE CALLBACK session=$_session] Errore gestito: $e\n$s');
    }
  }

  Future<void> _cancelSubscription(
    StreamSubscription<String> subscription,
    int epoch,
  ) async {
    try {
      await subscription.cancel();
    } catch (e, s) {
      onLog('[TCP CANCEL session=$epoch] Errore gestito: $e\n$s');
    }
  }

  void _destroySocket(Socket current, int epoch) {
    try {
      current.destroy();
    } catch (e, s) {
      onLog('[TCP CLOSE session=$epoch] Errore gestito: $e\n$s');
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopReconnecting();
    disconnect(reason: 'Pagina chiusa');
  }
}
