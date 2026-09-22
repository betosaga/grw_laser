import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/laser_page/laser_page.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'support/fake_robot_socket.dart';

LaserRobotSettings _settings() => LaserRobotSettings.fromJson({
  'seriale_robot': 'ROBOT-TEST',
  'ip_robot': '127.0.0.1',
  'tipo_controrotaia': 'controrotaiadoppia',
  'parametri': [
    {
      'parametro': 'job.rail_type',
      'tipo': 'string',
      'valore': 'piano',
      'valore_default': 'piano',
    },
  ],
});

class _Hub extends LaserPageHubController {
  @override
  Future<void> fetchRobotList() async {
    elencoRobotSettings = [_settings()];
  }

  @override
  Future<LaserRobotSettings?> fetchRobotDetail({
    required String serialeRobot,
  }) async => _settings();

  @override
  void storeSettingsListToDisk() {}
}

Future<void> _mount(WidgetTester tester, _Hub hub) async {
  hub.mySetState = (callback) => callback?.call();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          hub.context = context;
          return const Scaffold();
        },
      ),
    ),
  );
  addTearDown(hub.pageController.dispose);
}

void main() {
  setUpAll(() async {
    await Hive.openBox(Constants.HIVE_BOX_NAME, bytes: Uint8List(0));
  });

  tearDownAll(Hive.close);

  testWidgets('selection always asks and overrides both configured defaults', (
    tester,
  ) async {
    final hub = _Hub();
    await _mount(tester, hub);
    final selection = hub.selectRobotPressed();
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROBOT-TEST'));
    await tester.pumpAndSettle();

    expect(find.text('Tipo controrotaia'), findsOneWidget);
    expect(hub.laserPages, isEmpty);
    await tester.tap(find.text('Semplice'));
    await tester.pumpAndSettle();
    await selection;

    final controller = hub.laserPages.single.controller;
    addTearDown(controller.onDispose);
    expect(controller.controrotaiaModeValue, 'controrotaiasemplice');
    expect(
      controller.robotParametroValue('job.rail_type'),
      'controrotaiasemplice',
    );
  });

  testWidgets('cancelling the mode does not add a robot', (tester) async {
    final hub = _Hub();
    await _mount(tester, hub);
    final selection = hub.selectRobotPressed();
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROBOT-TEST'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    await selection;
    expect(hub.laserPages, isEmpty);
  });

  testWidgets('selecting an existing robot asks again before updating it', (
    tester,
  ) async {
    final hub = _Hub();
    final controller = LaserPageController(
      hubController: hub,
      settings: _settings(),
      selectedWorkMode: 'controrotaiasemplice',
    );
    addTearDown(controller.onDispose);
    hub.laserPages.add(LaserPage(controller: controller));
    await _mount(tester, hub);
    final selection = hub.selectRobotPressed();
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROBOT-TEST'));
    await tester.pumpAndSettle();
    expect(controller.controrotaiaModeValue, 'controrotaiasemplice');
    await tester.tap(find.text('Doppia'));
    await tester.pumpAndSettle();
    await selection;
    expect(hub.laserPages, hasLength(1));
    expect(controller.controrotaiaModeValue, 'controrotaiadoppia');
    expect(
      controller.robotParametroValue('job.rail_type'),
      'controrotaiadoppia',
    );
  });

  testWidgets('restored defaults cannot connect until a mode is selected', (
    tester,
  ) async {
    final hub = _Hub();
    final sockets = <FakeRobotSocket>[];
    final controller = LaserPageController(
      hubController: hub,
      settings: _settings(),
      tipoControrotaia: 'controrotaiasemplice',
      robotSocketConnector: (_, _, _) async {
        final socket = FakeRobotSocket();
        sockets.add(socket);
        return socket;
      },
    );
    addTearDown(controller.onDispose);
    await _mount(tester, hub);
    final connection = controller.startConnection();
    final concurrentConnection = controller.startConnection();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    expect(sockets, isEmpty);
    expect(find.text('Tipo controrotaia'), findsOneWidget);

    await tester.tap(find.text('Doppia'));
    await tester.pumpAndSettle();
    await Future.wait([connection, concurrentConnection]);
    expect(sockets, hasLength(1));
    sockets.single.message({'f': 'listening'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    final modeCommand = sockets.single.writes
        .map(jsonDecode)
        .firstWhere((message) => message['f'] == 'SETMODE');
    expect(modeCommand['tipo_controrotaia'], 'controrotaiadoppia');

    controller.closeSocket();
    final reconnect = controller.connettiRobot();
    await tester.pumpAndSettle();
    expect(find.text('Tipo controrotaia'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    await reconnect;
    await tester.pump(const Duration(seconds: 6));
    expect(sockets, hasLength(1));
    controller.onDispose();
  });
}
