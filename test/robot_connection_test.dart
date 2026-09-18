import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/services/robot/robot_command.dart';
import 'package:grw_laser/services/robot/robot_connection.dart';
import 'package:grw_laser/services/robot/robot_json_buffer.dart';
import 'support/fake_robot_socket.dart';

class Fixture {
  final List<FakeRobotSocket> sockets = [];
  final List<Map<String, dynamic>> received = [];
  final List<String> logs = [];
  final List<RobotCommandReceipt> changes = [];
  late final RobotConnection connection;
  int attempts = 0;

  Fixture(WidgetTester tester,
      {RobotSocketConnector? connector,
      void Function(RobotConnectionState, String)? onStateChanged,
      void Function(RobotCommandReceipt)? onCommandChanged,
      void Function(Map<String, dynamic>)? onMessage}) {
    connection = RobotConnection(
      now: () => tester.binding.clock.now(),
      connector: (host, port, timeout) async {
        attempts++;
        if (connector != null) return connector(host, port, timeout);
        final socket = FakeRobotSocket();
        sockets.add(socket);
        return socket;
      },
      onMessage: (message) {
        received.add(message);
        onMessage?.call(message);
      },
      onStateChanged: onStateChanged ?? (_, __) {},
      onCommandChanged: (receipt) {
        changes.add(receipt);
        onCommandChanged?.call(receipt);
      },
      onLog: logs.add,
    );
    addTearDown(connection.dispose);
  }

  FakeRobotSocket get socket => sockets.last;
}

void main() {
  testWidgets('connection refused errno 61 is handled and retries continue',
      (tester) async {
    var attempts = 0;
    final recovered = FakeRobotSocket();
    final f = Fixture(tester, connector: (_, __, ___) async {
      if (++attempts <= 3) {
        throw SocketException('Connection refused',
            osError: const OSError('Connection refused', 61),
            address: InternetAddress('192.168.10.130'),
            port: 58771);
      }
      return recovered;
    });
    f.connection.startReconnecting('robot');
    await f.connection.connect('robot');
    for (var i = 0; i < 3; i++) {
      expect(f.connection.state, RobotConnectionState.disconnected);
      await tester.pump(const Duration(seconds: 5));
    }
    expect(f.attempts, 4);
    expect(f.connection.socket, same(recovered));
    expect(
        f.logs.where((line) =>
            line.contains('[CONNECT') &&
            line.contains('Errore gestito') &&
            line.contains('errno = 61')),
        hasLength(3));
    f.connection.dispose();
  });

  testWidgets('setup failure consumes output error and permits another attempt',
      (tester) async {
    final broken = FakeRobotSocket()..failSetup = true;
    final recovered = FakeRobotSocket();
    var attempts = 0;
    final f = Fixture(tester,
        connector: (_, __, ___) async => attempts++ == 0 ? broken : recovered);
    await f.connection.connect('robot');
    await tester.pump();
    expect(broken.destroyed, isTrue);
    expect(f.connection.socket, isNull);
    await f.connection.connect('robot');
    expect(f.connection.socket, same(recovered));
    f.connection.dispose();
  });

  testWidgets('async cancellation and destroy errors cannot interrupt cleanup',
      (tester) async {
    final broken = FakeRobotSocket()
      ..failCancel = true
      ..failDestroy = true;
    final f = Fixture(tester, connector: (_, __, ___) async => broken);
    await f.connection.connect('robot');
    await tester.pump();
    final receipt = f.connection.send({'f': 'MOVE'});
    f.connection.disconnect();
    await tester.pump();
    expect(f.connection.state, RobotConnectionState.disconnected);
    expect(f.connection.socket, isNull);
    expect((await receipt.completed).status, RobotCommandStatus.unknown);
    expect(f.logs.any((line) => line.contains('[TCP CANCEL')), isTrue,
        reason: f.logs.join('\n'));
    expect(f.logs.any((line) => line.contains('[TCP CLOSE')), isTrue);
    f.connection.dispose();
  });

  testWidgets('notification errors do not kill connection or command timeouts',
      (tester) async {
    final f = Fixture(tester,
        onStateChanged: (_, __) => throw StateError('state callback'),
        onCommandChanged: (_) => throw StateError('command callback'));
    await f.connection.connect('robot');
    final receipt = f.connection.send({'f': 'PAUSE'});
    expect(f.connection.socket, isNotNull);
    await tester.pump(const Duration(seconds: 16));
    expect(receipt.outcome.status, RobotCommandStatus.unknown);
    expect(f.logs.any((line) => line.contains('[STATE CALLBACK')), isTrue);
    expect(f.logs.any((line) => line.contains('[COMMAND CALLBACK')), isTrue);
    f.connection.dispose();
  });

  testWidgets('scheduled async actions and UI failures are handled',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    f.connection.runAction(() => throw StateError('sync action'));
    f.connection.schedule(const Duration(seconds: 1), () async {
      await Future<void>.delayed(Duration.zero);
      throw StateError('async action');
    });
    var subsequentUiRan = false;
    f.connection.enqueueUiWork(() async => throw StateError('webview'));
    f.connection.enqueueUiWork(() async {
      subsequentUiRan = true;
    });
    await tester.pump(const Duration(seconds: 1));
    expect(f.logs.any((line) => line.contains('sync action')), isTrue);
    expect(f.logs.any((line) => line.contains('async action')), isTrue);
    expect(f.logs.any((line) => line.contains('webview')), isTrue);
    expect(subsequentUiRan, isTrue);
    f.connection.dispose();
  });

  testWidgets('invalid UTF8 closes just the socket and the next session works',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    f.socket.input.add(Uint8List.fromList([0xff]));
    await tester.pump();
    expect(f.connection.socket, isNull);
    expect(
        f.logs.any((line) =>
            line.contains('[TCP INPUT') && line.contains('Errore gestito')),
        isTrue);
    await f.connection.connect('robot');
    f.socket.message({'f': 'RobotInfo'});
    await tester.pump();
    expect(f.received.single['MSG']['f'], 'RobotInfo');
    f.connection.dispose();
  });

  test('JSON framing handles every split, concatenation, quotes and escapes',
      () {
    final objects = [
      {
        'MSG': {'f': 'A', 'text': 'modalità { " \\ }'}
      },
      {
        'MSG': {
          'f': 'B',
          'nested': {
            'items': [1, 2]
          }
        }
      },
    ];
    final raw = objects.map(jsonEncode).join('\r\n');
    for (var split = 0; split <= raw.length; split++) {
      final buffer = RobotJsonBuffer();
      final result = [
        ...buffer.add(raw.substring(0, split)),
        ...buffer.add(raw.substring(split)),
      ].map(jsonDecode).toList();
      expect(result, objects, reason: 'split=$split');
    }
    expect(() => RobotJsonBuffer(maxMessageLength: 8).add('{"large":').toList(),
        throwsFormatException);
  });

  testWidgets('one connect attempt and one reconnect timer', (tester) async {
    final candidate = Completer<Socket>();
    final f = Fixture(tester, connector: (_, __, ___) => candidate.future);
    f.connection.startReconnecting('robot');
    f.connection.startReconnecting('robot');
    unawaited(f.connection.connect('robot'));
    unawaited(f.connection.connect('robot'));
    await tester.pump(const Duration(seconds: 20));
    expect(f.attempts, 1);
    f.connection.stopReconnecting();
    candidate.completeError(const SocketException('unavailable'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    expect(f.attempts, 1, reason: 'No orphaned reconnection timer');
    f.connection.dispose();
  });

  testWidgets('late connect cannot resurrect a disposed session',
      (tester) async {
    final candidate = Completer<Socket>();
    final f = Fixture(tester, connector: (_, __, ___) => candidate.future);
    unawaited(f.connection.connect('robot'));
    f.connection.dispose();
    final socket = FakeRobotSocket();
    candidate.complete(socket);
    await tester.pump();
    expect(socket.destroyed, isTrue);
    expect(f.connection.socket, isNull);
    expect(f.connection.state, RobotConnectionState.disconnected);
  });

  testWidgets('changing host invalidates pending connection before retry',
      (tester) async {
    final pending = Completer<Socket>();
    final hosts = <String>[];
    final obsolete = FakeRobotSocket();
    final current = FakeRobotSocket();
    final f = Fixture(tester, connector: (host, _, __) {
      hosts.add(host);
      return host == 'old' ? pending.future : Future.value(current);
    });
    f.connection.startReconnecting('old');
    unawaited(f.connection.connect('old'));
    f.connection.startReconnecting('new');
    pending.complete(obsolete);
    await tester.pump();
    expect(obsolete.destroyed, isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(hosts, ['old', 'new']);
    expect(f.connection.socket, same(current));
    f.connection.dispose();
  });

  testWidgets('connect failure recovers once; manual stop prevents recovery',
      (tester) async {
    var fail = true;
    final socket = FakeRobotSocket();
    final f = Fixture(tester, connector: (_, __, ___) async {
      if (fail) throw const SocketException('unavailable');
      return socket;
    });
    f.connection.startReconnecting('robot');
    await f.connection.connect('robot');
    fail = false;
    await tester.pump(const Duration(seconds: 5));
    expect(f.connection.socket, same(socket));
    expect(f.attempts, 2);
    f.connection.stopReconnecting();
    f.connection.disconnect();
    await tester.pump(const Duration(seconds: 10));
    expect(f.attempts, 2);
    f.connection.dispose();
  });

  testWidgets('fresh JSON and UTF8 decoder for every session', (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    f.socket.receive('{"MSG":');
    await tester.pump();
    f.connection.disconnect();
    await f.connection.connect('robot');
    final bytes = utf8.encode(jsonEncode({
      'MSG': {'f': 'modalità'}
    }));
    final split = bytes.indexOf(0xc3) + 1;
    f.socket.input.add(Uint8List.fromList(bytes.sublist(0, split)));
    f.socket.input.add(Uint8List.fromList(bytes.sublist(split)));
    await tester.pump();
    expect(f.received.single['MSG']['f'], 'modalità');
    f.connection.dispose();
  });

  testWidgets('slow UI preserves receive order without blocking state',
      (tester) async {
    final gate = Completer<void>();
    final ui = <String>[];
    late Fixture f;
    f = Fixture(tester, onMessage: (message) {
      final name = message['MSG']['f'] as String;
      f.connection.enqueueUiWork(() async {
        ui.add(name);
        if (name == 'A') await gate.future;
      });
    });
    await f.connection.connect('robot');
    f.socket.receive('{"MSG":{"f":"A"}}{"MSG":{"f":"B"}}');
    await tester.pump();
    f.socket.message({'f': 'C'});
    await tester.pump();
    expect(f.received.map((m) => m['MSG']['f']), ['A', 'B', 'C']);
    expect(ui, ['A']);
    gate.complete();
    await tester.pump();
    expect(ui, ['A', 'B', 'C']);
    f.connection.dispose();
  });

  testWidgets('session cancels scheduled commands and queued UI work',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    final epoch = f.connection.session;
    final gate = Completer<void>();
    var obsoleteUiCalls = 0;
    f.connection.enqueueUiWork(() => gate.future);
    f.connection.enqueueUiWork(() async {
      obsoleteUiCalls++;
    });
    f.connection.schedule(const Duration(seconds: 2), () {
      f.connection.send({'f': 'SETMODE'});
    });
    await tester.pump();
    f.connection.disconnect();
    await f.connection.connect('robot');
    gate.complete();
    await tester.pump(const Duration(seconds: 3));
    expect(obsoleteUiCalls, 0);
    expect(f.socket.writes, isEmpty);
    final stale = f.connection.send({'f': 'MOVE'}, expectedSession: epoch);
    expect(stale.outcome.status, RobotCommandStatus.notSent);
    expect(f.socket.writes, isEmpty);
    f.connection.dispose();
  });

  testWidgets('not connected and invalid payloads are explicitly not sent',
      (tester) async {
    final f = Fixture(tester);
    final absent = f.connection.send({'f': 'MOVE'});
    expect(absent.accepted, isFalse);
    expect((await absent.completed).status, RobotCommandStatus.notSent);
    await f.connection.connect('robot');
    final invalid = f.connection.send({'f': 'MOVE', 'bad': Object()});
    expect(invalid.outcome.status, RobotCommandStatus.notSent);
    expect(f.socket.writes, isEmpty);
    f.connection.dispose();
  });

  testWidgets('TCP write is waiting; status is an observation, not an ACK',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    final receipt = f.connection.send({'f': 'PAUSE'});
    expect(receipt.outcome.status, RobotCommandStatus.waiting);
    expect(f.socket.writes.map(jsonDecode), [
      {'f': 'PAUSE'}
    ]);
    f.socket.message({'f': 'RobotStatus', 'status': 'WELDING'});
    await tester.pump();
    expect(receipt.outcome.status, RobotCommandStatus.waiting);
    f.socket.message({'f': 'RobotStatus', 'status': 'PAUSED'});
    await tester.pump();
    expect((await receipt.completed).status, RobotCommandStatus.stateObserved);
    expect(receipt.outcome.reason, contains('non è una conferma'));
    f.connection.dispose();
  });

  testWidgets('compatible response; ambiguous responses complete no command',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    final point = f.connection.send({'f': 'SETPOINT'});
    f.socket.message({
      'f': 'getPoint',
      'Point': {'x': 1}
    });
    await tester.pump();
    expect(point.outcome.status, RobotCommandStatus.responseObserved);
    final a = f.connection.send({'f': 'MOVE'});
    final b = f.connection.send({'f': 'MOVETO'});
    f.socket.message({'f': 'Movement', 'Status': 'Stopped'});
    await tester.pump();
    expect(a.outcome.status, RobotCommandStatus.waiting);
    expect(b.outcome.status, RobotCommandStatus.waiting);
    f.connection.dispose();
  });

  testWidgets('timeout and disconnect produce unknown with no replay',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    final oldSocket = f.socket;
    final receipt = f.connection.send({'f': 'WELD'});
    await tester.pump(const Duration(seconds: 16));
    expect(receipt.outcome.status, RobotCommandStatus.unknown);
    oldSocket.message({'f': 'RobotStatus', 'status': 'WELDING'});
    await tester.pump();
    expect(receipt.outcome.status, RobotCommandStatus.unknown);
    expect(oldSocket.writes, hasLength(1));
    final pending = f.connection.send({'f': 'MOVE'});
    f.connection.disconnect();
    expect((await pending.completed).status, RobotCommandStatus.unknown);
    await f.connection.connect('robot');
    expect(f.socket.writes, isEmpty);
    f.connection.dispose();
  });

  testWidgets('tracking limit never blocks STOP or OFF commands',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    final first = f.connection.send({'f': 'MOVE'});
    for (var i = 0; i < 255; i++) {
      f.connection.send({'f': 'MOVE'});
    }
    final stop = f.connection.send({'f': 'STOPCORDONE'});
    final off = f.connection.send({'f': 'GAS-OFF'});
    expect(first.outcome.status, RobotCommandStatus.unknown);
    expect(stop.accepted, isTrue);
    expect(off.accepted, isTrue);
    expect(f.socket.writes, hasLength(258));
    f.connection.dispose();
  });

  testWidgets('read, write and output-side errors close pending commands',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    f.socket.failWrite = true;
    final failed = f.connection.send({'f': 'MOVE'});
    expect(failed.outcome.status, RobotCommandStatus.unknown);
    expect(f.connection.socket, isNull);
    await f.connection.connect('robot');
    final pending = f.connection.send({'f': 'MOVE'});
    f.socket.outputDone.completeError(const SocketException('output error'));
    await tester.pump();
    expect(pending.outcome.status, RobotCommandStatus.unknown);
    expect(f.connection.socket, isNull);
    await f.connection.connect('robot');
    f.socket.input.addError(const SocketException('input error'));
    await tester.pump();
    expect(f.connection.socket, isNull);
    f.connection.dispose();
  });

  testWidgets('silent half-open connection expires and reconnects',
      (tester) async {
    final f = Fixture(tester);
    f.connection.startReconnecting('robot');
    await f.connection.connect('robot');
    final old = f.socket;
    await tester.pump(const Duration(seconds: 31));
    expect(old.destroyed, isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(f.attempts, 2);
    expect(f.connection.state, RobotConnectionState.awaitingData);
    f.connection.dispose();
  });

  testWidgets('lost RobotStatus detected even with other incoming traffic',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    for (var i = 0; i < 4; i++) {
      f.socket.message({
        'f': 'RobotStatus',
        'Position': '[0,0,0,0,0,0]',
        'Velocity': '[0,0,0,0,0,0]'
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    expect(f.connection.statusTimeout, const Duration(seconds: 15));
    for (var i = 0; i < 4; i++) {
      f.socket.message({'f': 'WeldInfo'});
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
    }
    expect(f.connection.socket, isNull);
    expect(f.logs.any((s) => s.contains('RobotStatus non aggiornato')), isTrue);
    f.connection.dispose();
  });

  testWidgets('slow telemetry sets a measured rather than fixed deadline',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    for (var i = 0; i < 4; i++) {
      f.socket.message({
        'f': 'RobotStatus',
        'Position': [0, 0, 0, 0, 0, 0],
        'Velocity': [0, 0, 0, 0, 0, 0]
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));
    }
    expect(f.connection.statusTimeout, const Duration(seconds: 40));
    await tester.pump(const Duration(seconds: 25));
    expect(f.connection.socket, isNotNull);
    f.connection.dispose();
  });

  testWidgets('bad messages logged; later complete messages still processed',
      (tester) async {
    final f = Fixture(tester);
    await f.connection.connect('robot');
    f.socket.receive('{bad}{"MSG":{"f":"RobotInfo"}}');
    await tester.pump();
    expect(f.received.single['MSG']['f'], 'RobotInfo');
    expect(f.logs.any((s) => s.contains('Errore elaborazione')), isTrue);
    f.connection.dispose();
  });

  test('real localhost TCP preserves outgoing JSON and incoming UTF8',
      () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = Completer<Socket>();
    final serverSubscription = server.listen(accepted.complete);
    final response = Completer<Map<String, dynamic>>();
    final connection = RobotConnection(
      port: server.port,
      onMessage: response.complete,
      onStateChanged: (_, __) {},
      onCommandChanged: (_) {},
      onLog: (_) {},
    );
    Socket? peer;
    try {
      await connection.connect('127.0.0.1');
      peer = await accepted.future.timeout(const Duration(seconds: 3));
      final buffer = RobotJsonBuffer();
      final request = peer
          .cast<List<int>>()
          .transform(utf8.decoder)
          .expand(buffer.add)
          .first;
      final receipt = connection.send({'f': 'PAUSE'});
      expect(jsonDecode(await request.timeout(const Duration(seconds: 3))),
          {'f': 'PAUSE'});
      expect(receipt.outcome.status, RobotCommandStatus.waiting);
      final bytes = utf8.encode('{"MSG":{"f":"RobotInfo","Model":"modalità"}}');
      final split = bytes.indexOf(0xc3) + 1;
      peer.add(bytes.sublist(0, split));
      await peer.flush();
      peer.add(bytes.sublist(split));
      await peer.flush();
      expect(
          (await response.future.timeout(const Duration(seconds: 3)))['MSG']
              ['Model'],
          'modalità');
    } finally {
      connection.dispose();
      peer?.destroy();
      await serverSubscription.cancel();
      await server.close();
    }
  });
}
