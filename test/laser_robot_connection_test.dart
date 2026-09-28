import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/laser_page/components/laser_log_window.dart';
import 'package:grw_laser/pages/laser_page/laser_page.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:grw_laser/services/robot/robot_command.dart';
import 'package:grw_laser/services/robot/robot_connection.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'support/fake_robot_socket.dart';

void main() {
  late Directory hiveDirectory;
  setUpAll(() async {
    hiveDirectory =
        await Directory.systemTemp.createTemp('grw-connection-test-');
    Hive.init(hiveDirectory.path);
    await Hive.openBox(Constants.HIVE_BOX_NAME);
  });
  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  LaserPageController controller(List<FakeRobotSocket> sockets,
      {String ipRobot = '127.0.0.1', RobotSocketConnector? connector}) {
    final result = LaserPageController(
      hubController: LaserPageHubController(),
      selectedWorkMode: 'controrotaiasemplice',
      settings: LaserRobotSettings(
        serialeRobot: 'TEST',
        ipRobot: ipRobot,
        ipServer: '127.0.0.99',
        pinGas: '1',
        pinLaser: '3',
        pinMassa: '4',
        color: '',
      ),
      robotSocketConnector: connector ?? (_, __, ___) async {
        final socket = FakeRobotSocket();
        sockets.add(socket);
        return socket;
      },
    );
    result.mySetState = (callback) => callback?.call();
    addTearDown(result.onDispose);
    return result;
  }

  testWidgets('each selected robot connects to its configured robot IP',
      (tester) async {
    final destinations = <String>[];
    Future<Socket> connect(String host, int port, Duration _) async {
      destinations.add('$host:$port');
      return FakeRobotSocket();
    }
    final first = controller([], ipRobot: '192.168.1.10', connector: connect);
    final second = controller([], ipRobot: '192.168.1.20', connector: connect);
    await first.startConnection();
    await second.startConnection();
    expect(destinations, ['192.168.1.10:20002', '192.168.1.20:20002']);
    first.onDispose();
    second.onDispose();
  });

  for (final pending in [false, true]) {
    testWidgets('settings IP change replaces connection (pending=$pending)',
        (tester) async {
      final oldAttempt = Completer<Socket>();
      final oldSocket = FakeRobotSocket();
      final newSocket = FakeRobotSocket();
      final reconnectSocket = FakeRobotSocket();
      final hosts = <String>[];
      final ports = <int>[];
      final c = controller([], connector: (host, port, _) async {
        hosts.add(host);
        ports.add(port);
        if (host == '127.0.0.1') {
          return pending ? oldAttempt.future : oldSocket;
        }
        return hosts.length == 2 ? newSocket : reconnectSocket;
      });
      c.hubController.laserPages.add(LaserPage(controller: c));
      unawaited(c.startConnection());
      await tester.pump();
      expect(hosts, ['127.0.0.1']);

      await tester.runAsync(() async {
        unawaited(c.setRobotSettings(newSettings: LaserRobotSettings.fromJson({
          ...c.settings.toJson(),
          'ip_robot': ' 127.0.0.2 ',
        })));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      expect(hosts, ['127.0.0.1', '127.0.0.2']);
      expect(c.socket, same(newSocket));
      expect(c.connectionStatus, isTrue);
      expect(c.settings.ipRobot, '127.0.0.2');
      final stored = jsonDecode(Hive.box(Constants.HIVE_BOX_NAME)
          .get(Constants.HIVE_LASER_SETTINGS_LIST_KEY) as String) as List;
      expect(stored.single['ip_robot'], '127.0.0.2');

      if (pending) {
        oldAttempt.complete(oldSocket);
        await tester.pump();
      }
      expect(oldSocket.destroyed, isTrue);
      expect(c.socket, same(newSocket));
      await c.sendMessageToRobot({'f': 'TEST'});
      expect(jsonDecode(newSocket.writes.single)['f'], 'TEST');
      c.closeSocket();
      await tester.pump(const Duration(seconds: 5));
      expect(hosts, ['127.0.0.1', '127.0.0.2', '127.0.0.2']);
      expect(ports, [20002, 20002, 20002]);
      expect(c.socket, same(reconnectSocket));
      c.onDispose();
    });
  }

  testWidgets('logs refresh their window without rebuilding robot controls',
      (tester) async {
    final c = controller(<FakeRobotSocket>[]);
    var pageUpdates = 0;
    c.mySetState = (callback) {
      pageUpdates++;
      callback?.call();
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Stack(children: [
        Builder(builder: (context) {
          c.printLog('Log durante build');
          return const SizedBox.shrink();
        }),
        LaserLogWindow(controller: c),
      ])),
    ));
    for (var i = 0; i < 80; i++) {
      c.printLog('Risposta robot $i');
    }
    c.printLog({
      'MSG': {'f': 'RobotInfo'}
    });
    await tester.pump(const Duration(milliseconds: 100));
    expect(pageUpdates, 0);
    expect(find.textContaining('Risposta robot 79'), findsOneWidget);
    expect(find.textContaining('RobotInfo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    c.onDispose();
    // Late diagnostic callbacks may record a message but must not notify
    // disposed widgets or schedule another publication timer.
    c.printLog('Log dopo chiusura');
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('listening grace period does not block following robot status',
      (tester) async {
    final sockets = <FakeRobotSocket>[];
    final c = controller(sockets);
    await c.startConnection();
    sockets.last.receive('{"MSG":{"f":"listening"}}'
        '{"MSG":{"f":"RobotStatus","status":"PAUSED"}}');
    await tester.pump();
    expect(c.weldingStatus, LaserPageController.weldingStatusPaused);
    expect(sockets.last.writes, isEmpty);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(sockets.last.writes.map(jsonDecode).single['f'], 'SETMODE');
    c.onDispose();
  });

  testWidgets('late HOMEREACH and prolonged silence keep the same connection',
      (tester) async {
    final sockets = <FakeRobotSocket>[];
    final c = controller(sockets);
    await c.startConnection();
    final socket = sockets.single;
    socket.message({'f': 'listening'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(socket.writes.map(jsonDecode).single['f'], 'SETMODE');

    // Even when SETMODE has no reply, neither its timeout nor the reconnect
    // timer may close a healthy socket or send the initialization again.
    await tester.pump(const Duration(minutes: 30));
    expect(c.robotCommandHistory.single.outcome.status,
        RobotCommandStatus.unknown);
    expect(c.connectionStatus, isTrue);
    expect(c.isWaitingHomeReach, isTrue);
    expect(c.socket, same(socket));
    expect(socket.destroyed, isFalse);
    expect(sockets, hasLength(1));
    expect(socket.writes, hasLength(1));

    socket.message({
      'f': 'RobotStatus',
      'Status': 'HOMEREACH',
      'Position': [10, 20, 30, 0, 0, 0],
      'armPosition': 'DX',
    });
    await tester.pump();
    expect(c.homeReachReceived, isTrue);
    expect(c.isWaitingHomeReach, isFalse);

    // Once HOME is reached, a lack of telemetry must not reset that state.
    await tester.pump(const Duration(minutes: 30));
    expect(c.connectionStatus, isTrue);
    expect(c.homeReachReceived, isTrue);
    expect(c.isWaitingHomeReach, isFalse);
    expect(c.socket, same(socket));
    expect(socket.destroyed, isFalse);
    expect(sockets, hasLength(1));
    expect(socket.writes, hasLength(1));
    c.onDispose();
  });

  testWidgets('slow webview and malformed message do not block or unlock robot',
      (tester) async {
    final sockets = <FakeRobotSocket>[];
    final c = controller(sockets);
    final gate = Completer<void>();
    c.webviewDispatchFlutterMessage = (_) => gate.future;
    await c.startConnection();
    sockets.last.receive('{"MSG":{"f":"WEBVIEW_MESSAGE","data":{}}}'
        '{"MSG":{"f":"FrameSet","Status":"invalid"}}'
        '{"MSG":{"f":"RobotStatus","status":"PAUSED"}}');
    await tester.pump();
    expect(c.weldingStatus, LaserPageController.weldingStatusPaused);
    expect(c.canMoveRobot, isFalse);
    expect(c.logString, contains('Errore elaborazione'));
    c.onDispose();
    gate.complete();
    await tester.pump();
  });

  testWidgets('close cancels old SETMODE and gas-off timers', (tester) async {
    final sockets = <FakeRobotSocket>[];
    final c = controller(sockets);
    await c.startConnection();
    sockets.last.message({'f': 'listening'});
    c.gasTouchedUp();
    await tester.pump();
    c.closeSocket();
    await c.startConnection();
    await tester.pump(const Duration(seconds: 3));
    expect(sockets.last.writes, isEmpty);
    c.onDispose();
  });

  testWidgets('timeout clears pending control and appears only in log window',
      (tester) async {
    final c = controller(<FakeRobotSocket>[]);
    await c.startConnection();
    c.pendingRobotTargetStatus = 'PAUSED';
    c.isPausingResuming = true;
    final receipt = await c.sendMessageToRobot({'f': 'PAUSE'});
    await tester.pump(const Duration(seconds: 16));
    expect(receipt.outcome.status, RobotCommandStatus.unknown);
    expect(c.isPausingResuming, isFalse);
    expect(c.logString, contains('esecuzione sconosciuta'));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: Stack(children: [LaserLogWindow(controller: c)]),
    )));
    expect(find.textContaining('esecuzione sconosciuta'), findsOneWidget);
    expect(find.textContaining('Comando non reinviato'), findsOneWidget);
    expect(find.text('Dettagli'), findsNothing);
    expect(tester.takeException(), isNull);
    c.onDispose();
  });

  testWidgets('connection state updates without a mounted widget',
      (tester) async {
    final sockets = <FakeRobotSocket>[];
    final c = controller(sockets)..mySetState = null;
    await c.startConnection();
    expect(c.connectionStatus, isTrue);
    expect(c.canMoveRobot, isFalse);
    c.closeSocket();
    expect(c.connectionStatus, isFalse);
    expect(c.homeReachReceived, isFalse);
    c.onDispose();
  });
}
