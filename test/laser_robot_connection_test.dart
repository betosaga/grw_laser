import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/laser_page/components/laser_communication_status.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:grw_laser/services/robot/robot_command.dart';
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

  LaserPageController controller(List<FakeRobotSocket> sockets) {
    final result = LaserPageController(
      hubController: LaserPageHubController(),
      settings: LaserRobotSettings(
        serialeRobot: 'TEST',
        ipRobot: '127.0.0.1',
        ipServer: '127.0.0.1',
        pinGas: '1',
        pinLaser: '3',
        pinMassa: '4',
        color: '',
      ),
      robotSocketConnector: (_, __, ___) async {
        final socket = FakeRobotSocket();
        sockets.add(socket);
        return socket;
      },
    );
    result.mySetState = (callback) => callback?.call();
    addTearDown(result.onDispose);
    return result;
  }

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

  testWidgets('timeout clears pending control and is visible in UI',
      (tester) async {
    final c = controller(<FakeRobotSocket>[]);
    await c.startConnection();
    c.pendingRobotTargetStatus = 'PAUSED';
    c.isPausingResuming = true;
    final receipt = await c.sendMessageToRobot({'f': 'PAUSE'});
    await tester.pump(const Duration(seconds: 16));
    expect(receipt.outcome.status, RobotCommandStatus.unknown);
    expect(c.isPausingResuming, isFalse);
    expect(c.robotCommunicationWarning, contains('esecuzione sconosciuta'));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: LaserCommunicationStatus(controller: c),
    )));
    expect(find.textContaining('Esito sconosciuto'), findsOneWidget);
    expect(find.textContaining('Comando non reinviato'), findsOneWidget);
    await tester.tap(find.text('Dettagli'));
    await tester.pumpAndSettle();
    expect(find.text('Comunicazione con il robot'), findsOneWidget);
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
