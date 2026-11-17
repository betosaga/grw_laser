import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/pages/laser_page/components/laser_top_actions_bar.dart';
import 'package:grw_laser/pages/laser_page/laser_panel_state.dart';
import 'package:grw_laser/pages/laser_page/laser_page.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'support/fake_robot_socket.dart';

LaserRobotSettings _settings() => LaserRobotSettings.fromJson({
  'seriale_robot': 'ROBOT-TEST',
  'ip_robot': '127.0.0.1',
  'modalita_abilitate': [
    {'codice': 'controrotaiasemplice', 'nome': 'Semplice'},
    {'codice': 'controrotaiadoppia', 'nome': 'Doppia'},
    {'codice': 'piano-rotolamento', 'nome': 'Piano di rotolamento'},
  ],
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
  LaserRobotSettings detail = _settings();
  @override
  Future<void> fetchRobotList() async {
    elencoRobotSettings = [_settings()];
  }

  @override
  Future<LaserRobotSettings?> fetchRobotDetail({
    required String serialeRobot,
  }) async => detail;

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

  test(
    'enabled modes survive persistence; absent or invalid codes enable nothing',
    () {
      final restored = robotLaserSettingsFromJson(
        robotLaserSettingsToJson(_settings()),
      );
      expect(restored.modalitaAbilitate.map((m) => m.codice), [
        'controrotaiasemplice',
        'controrotaiadoppia',
        'piano',
      ]);
      for (final value in [
        null,
        [],
        [
          {'codice': null, 'nome': null},
        ],
      ]) {
        expect(
          LaserRobotSettings.fromJson({
            'modalita_abilitate': value,
          }).modalitaAbilitate,
          isEmpty,
        );
      }
    },
  );

  test('server and legacy modes never select an initial work mode', () async {
    final controller = LaserPageController(
      hubController: _Hub(),
      settings: _settings(),
      tipoControrotaia: 'controrotaiadoppia',
    );
    addTearDown(controller.onDispose);
    expect(controller.controrotaiaModeValue, isEmpty);
    for (final command in ['SETMODE', 'WELD']) {
      final receipt = await controller.sendMessageToRobot({
        'f': command,
        'tipo_controrotaia': 'piano',
        'job.rail_type': 'piano',
      });
      expect(receipt.accepted, isFalse);
    }
    expect(
      () => LaserPageController(
        hubController: _Hub(),
        settings: _settings(),
        selectedWorkMode: 'invalid',
      ),
      throwsArgumentError,
    );
  });

  for (final mode in ['controrotaiasemplice', 'controrotaiadoppia', 'piano']) {
    testWidgets('server refresh cannot replace $mode before SETMODE or WELD', (
      tester,
    ) async {
      final sockets = <FakeRobotSocket>[];
      final controller = LaserPageController(
        hubController: _Hub(),
        settings: _settings(),
        selectedWorkMode: mode,
        robotSocketConnector: (_, _, _) async {
          final socket = FakeRobotSocket();
          sockets.add(socket);
          return socket;
        },
      );
      addTearDown(controller.onDispose);
      controller.mySetState = (callback) => callback?.call();
      await controller.startConnection();
      sockets.single.message({'f': 'listening'});
      await tester.pump();
      // A fresh server response arrives during the startup grace period.
      await controller.setRobotSettings(newSettings: _settings());
      expect(controller.controrotaiaModeValue, mode);
      expect(controller.robotParametroValue('job.rail_type'), mode);
      // Generic parameter updates must not override the explicit selection.
      controller.updateRobotParametroValue('job.rail_type', 'piano');
      expect(controller.robotParametroValue('job.rail_type'), mode);
      await tester.pump(const Duration(milliseconds: 1500));
      final commands = sockets.single.writes.map(jsonDecode).toList();
      expect(commands.where((m) => m['f'] == 'SETMODE'), hasLength(1));
      expect(
        commands.singleWhere((m) => m['f'] == 'SETMODE')['tipo_controrotaia'],
        mode,
      );
      await controller.sendMessageToRobot({
        'f': 'WELD',
        'job.rail_type': 'server-default',
      });
      expect(jsonDecode(sockets.single.writes.last)['job.rail_type'], mode);
      controller.onDispose();
    });
  }

  for (final initial in [
    'controrotaiasemplice',
    'controrotaiadoppia',
    'piano',
  ]) {
    for (final target in [
      'controrotaiasemplice',
      'controrotaiadoppia',
      'piano',
    ]) {
      if (initial == target) continue;
      testWidgets('connected dialog changes $initial to $target until HOME', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final socket = FakeRobotSocket();
        final controller = LaserPageController(
          hubController: _Hub(),
          settings: _settings(),
          selectedWorkMode: initial,
          robotSocketConnector: (_, _, _) async => socket,
        );
        addTearDown(controller.onDispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  controller.context = context;
                  controller.mySetState = (callback) =>
                      setState(() => callback?.call());
                  return LaserTopActionsBar(controller: controller);
                },
              ),
            ),
          ),
        );
        await controller.startConnection();
        socket.message({'f': 'listening'});
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1500));
        socket.message({'f': 'RobotStatus', 'Status': 'HOMEREACH'});
        await tester.pumpAndSettle();
        controller.points.points.add(Point(x: 1, y: 2, z: 3));
        final before = socket.writes.length;
        await tester.tap(find.text('ROBOT-TEST'));
        await tester.pumpAndSettle();
        expect(find.text('Cambia tipo controrotaia'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'CONFERMA'))
              .onPressed,
          isNull,
        );
        final label = controller.settings.modalitaAbilitate
            .singleWhere((mode) => mode.codice == target)
            .nome;
        await tester.tap(find.widgetWithText(RadioListTile<String>, label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ANNULLA'));
        await tester.pumpAndSettle();
        expect(controller.controrotaiaModeValue, initial);
        expect(controller.points.points, hasLength(1));
        expect(socket.writes, hasLength(before));
        await tester.tap(find.text('ROBOT-TEST'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(RadioListTile<String>, label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONFERMA'));
        await tester.pumpAndSettle();
        final commands = socket.writes.skip(before).map(jsonDecode).toList();
        expect(commands.map((m) => m['f']), ['RESETSAFEPOSITION', 'SETMODE']);
        expect(commands.last['tipo_controrotaia'], target);
        expect(controller.robotParametroValue('job.rail_type'), target);
        expect(controller.points.points, isEmpty);
        expect(controller.isWaitingHomeReach, isTrue);
        expect(controller.canChangeWorkMode, isFalse);
        expect(await controller.sendSetModeControrotaia(initial), isFalse);
        socket.message({'f': 'RobotStatus', 'Status': 'HOMEREACH'});
        await tester.pumpAndSettle();
        expect(controller.canChangeWorkMode, isTrue);
        expect(controller.controrotaiaModeValue, target);
        controller.onDispose();
      });
    }
  }

  testWidgets(
    'runtime change rejects unavailable modes and disconnected robot',
    (tester) async {
      final socket = FakeRobotSocket();
      final controller = LaserPageController(
        hubController: _Hub(),
        settings: LaserRobotSettings.fromJson({
          ..._settings().toJson(),
          'modalita_abilitate': [
            {'codice': 'piano', 'nome': 'Piano'},
          ],
        }),
        selectedWorkMode: 'piano',
        robotSocketConnector: (_, _, _) async => socket,
      );
      addTearDown(controller.onDispose);
      controller.mySetState = (callback) => callback?.call();
      await controller.startConnection();
      controller.homeReachReceived = true;
      expect(
        await controller.sendSetModeControrotaia('controrotaiasemplice'),
        isFalse,
      );
      expect(await controller.sendSetModeControrotaia('invalid'), isFalse);
      expect(await controller.sendSetModeControrotaia('piano'), isFalse);
      controller.pageState = LaserPanelState.tipoSaldatura;
      expect(controller.canChangeWorkMode, isFalse);
      controller.closeSocket();
      controller.pageState = LaserPanelState.joystick;
      expect(await controller.sendSetModeControrotaia('piano'), isFalse);
      expect(socket.writes, isEmpty);
      expect(controller.controrotaiaModeValue, 'piano');
      controller.onDispose();
    },
  );

  testWidgets(
    'only enabled modes from fresh detail are offered, with database names',
    (tester) async {
      final hub = _Hub();
      hub.detail = LaserRobotSettings.fromJson({
        ..._settings().toJson(),
        'modalita_abilitate': [
          {'codice': 'piano', 'nome': 'Lavorazione piano'},
        ],
      });
      await _mount(tester, hub);
      final selection = hub.selectRobotPressed();
      await tester.pumpAndSettle();
      await tester.tap(find.text('ROBOT-TEST'));
      await tester.pumpAndSettle();
      expect(find.text('Doppia'), findsNothing);
      expect(find.text('Semplice'), findsNothing);
      expect(hub.laserPages, isEmpty);
      await tester.tap(find.text('Lavorazione piano'));
      await tester.pumpAndSettle();
      await selection;
      final controller = hub.laserPages.single.controller;
      addTearDown(controller.onDispose);
      expect(controller.controrotaiaModeValue, 'piano');
      expect(controller.settings.modalitaAbilitate.single.codice, 'piano');
    },
  );

  for (final modes in [null, []]) {
    testWidgets('no enabled modes blocks selection (modes=$modes)', (
      tester,
    ) async {
      final hub = _Hub();
      hub.detail = LaserRobotSettings.fromJson({
        ..._settings().toJson(),
        'modalita_abilitate': modes,
      });
      await _mount(tester, hub);
      final selection = hub.selectRobotPressed();
      await tester.pumpAndSettle();
      await tester.tap(find.text('ROBOT-TEST'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nessuna lavorazione abilitata'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Annulla'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      await selection;
      expect(hub.laserPages, isEmpty);
    });
  }

  testWidgets('reconnection refreshes permissions and blocks revoked modes', (
    tester,
  ) async {
    final hub = _Hub();
    hub.detail = LaserRobotSettings.fromJson({
      ..._settings().toJson(),
      'modalita_abilitate': [],
    });
    final sockets = <FakeRobotSocket>[];
    final controller = LaserPageController(
      hubController: hub,
      settings: _settings(),
      robotSocketConnector: (_, _, _) async {
        final socket = FakeRobotSocket();
        sockets.add(socket);
        return socket;
      },
    );
    addTearDown(controller.onDispose);
    await _mount(tester, hub);
    final connection = controller.startConnection();
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Nessuna lavorazione abilitata'),
      findsOneWidget,
    );
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    await connection;
    expect(sockets, isEmpty);
  });

  testWidgets('selection always asks and overrides both configured defaults', (
    tester,
  ) async {
    final hub = _Hub();
    await _mount(tester, hub);
    final selection = hub.selectRobotPressed();
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROBOT-TEST'));
    await tester.pumpAndSettle();

    expect(find.text('Tipo di lavorazione'), findsOneWidget);
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

  testWidgets('page startup connects immediately with the selected piano mode', (
    tester,
  ) async {
    final hub = _Hub();
    await _mount(tester, hub);
    final sockets = <FakeRobotSocket>[];
    final controller = LaserPageController(
      hubController: hub,
      settings: _settings(),
      selectedWorkMode: 'piano-rotolamento',
      robotSocketConnector: (_, _, _) async {
        final socket = FakeRobotSocket();
        sockets.add(socket);
        return socket;
      },
    );
    addTearDown(controller.onDispose);
    controller.mySetState = (callback) => callback?.call();
    controller.onInit();
    await tester.pump();
    await tester.pump();
    expect(sockets, hasLength(1));
    expect(find.text('Tipo di lavorazione'), findsNothing);
    sockets.single.message({'f': 'listening'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(
      sockets.single.writes.map(jsonDecode).firstWhere(
        (message) => message['f'] == 'SETMODE',
      )['tipo_controrotaia'],
      'piano',
    );
    controller.onDispose();
  });

  testWidgets('reselecting a disconnected robot starts its connection', (
    tester,
  ) async {
    final hub = _Hub();
    await _mount(tester, hub);
    final sockets = <FakeRobotSocket>[];
    final controller = LaserPageController(
      hubController: hub,
      settings: _settings(),
      selectedWorkMode: 'piano',
      robotSocketConnector: (_, _, _) async {
        final socket = FakeRobotSocket();
        sockets.add(socket);
        return socket;
      },
    );
    addTearDown(controller.onDispose);
    hub.laserPages.add(LaserPage(controller: controller));
    final selection = hub.selectRobotPressed();
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROBOT-TEST'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Piano di rotolamento'));
    await tester.pumpAndSettle();
    await selection;
    expect(hub.laserPages, hasLength(1));
    expect(sockets, hasLength(1));
    expect(controller.controrotaiaModeValue, 'piano');
    expect(find.text('Tipo di lavorazione'), findsNothing);
    controller.onDispose();
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
      robotSocketConnector: (_, _, _) async => FakeRobotSocket(),
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
    controller.onDispose();
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
    expect(find.text('Tipo di lavorazione'), findsOneWidget);

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
    expect(find.text('Tipo di lavorazione'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    await reconnect;
    await tester.pump(const Duration(seconds: 6));
    expect(sockets, hasLength(1));
    controller.onDispose();
  });
}
