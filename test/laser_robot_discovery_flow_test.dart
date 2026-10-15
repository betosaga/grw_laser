import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/laser_page/components/laser_choose_robot_button.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/components/select_laser_robot_settings_dialog.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:grw_laser/services/robot/robot_discovery.dart';
import 'package:hive_flutter/hive_flutter.dart';

LaserRobotSettings _settings(String serial) => LaserRobotSettings.fromJson({
  'seriale_robot': serial,
  'ip_robot': '10.0.0.99',
  'ip_server': '10.0.0.100',
  'color': '#123456',
  'modalita_abilitate': [
    {'codice': 'piano', 'nome': 'Piano'},
  ],
});

class _Discovery extends RobotDiscovery {
  _Discovery(this.events);
  final List<String> events;
  final result = Completer<List<DiscoveredRobot>>();
  int calls = 0;
  @override
  Future<List<DiscoveredRobot>> scan() {
    events.add('scan');
    calls++;
    return result.future;
  }

  @override
  void cancel() {
    super.cancel();
    if (!result.isCompleted) result.complete([]);
  }
}

class _Hub extends LaserPageHubController {
  _Hub(this.discovery, this.events) : super(discoveryFactory: () => discovery);
  final _Discovery discovery;
  final List<String> events;
  final serverList = [_settings('123-GRW'), _settings('456-OTHER')];
  @override
  Future<void> fetchRobotList() async {
    events.add('fetch');
    elencoRobotSettings = serverList;
  }

  @override
  Future<LaserRobotSettings?> fetchRobotDetail({
    required String serialeRobot,
  }) async {
    events.add('detail:$serialeRobot');
    return _settings(serialeRobot);
  }

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
          return Scaffold(body: LaserChooseRobotButton(controller: hub));
        },
      ),
    ),
  );
  addTearDown(hub.dispose);
}

void main() {
  setUpAll(() async {
    await Hive.openBox(Constants.HIVE_BOX_NAME, bytes: Uint8List(0));
  });
  tearDownAll(Hive.close);
  tearDown(() => Constants.ROBOT_SEARCH_MODE = 'FLAT');

  for (final mode in ['FLAT', '', 'unknown', 'scan']) {
    testWidgets('$mode uses the original full list without scanning', (
      tester,
    ) async {
      Constants.ROBOT_SEARCH_MODE = mode;
      final events = <String>[];
      final discovery = _Discovery(events);
      final hub = _Hub(discovery, events);
      await _mount(tester, hub);
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(events, ['fetch']);
      final dialog = tester.widget<SelectLaserRobotSettingsDialog>(
        find.byType(SelectLaserRobotSettingsDialog),
      );
      expect(dialog.list.length, 2);
      expect(dialog.list.first.ipRobot, '10.0.0.99');
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
    'SCAN downloads first, waits for completion, matches both identity fields and uses discovered IP',
    (tester) async {
      Constants.ROBOT_SEARCH_MODE = 'SCAN';
      final events = <String>[];
      final discovery = _Discovery(events);
      final hub = _Hub(discovery, events);
      await _mount(tester, hub);
      final selection = hub.addRobotPressed();
      await tester.pump();
      await hub.addRobotPressed(); // Double tap does not start a second scan.
      expect(events, ['fetch', 'scan']);
      expect(hub.isLoadingRobots, isTrue);
      expect(find.byType(SelectLaserRobotSettingsDialog), findsNothing);
      discovery.result.complete([
        const DiscoveredRobot(ip: '192.168.10.7', serial: '123', model: 'GRW'),
        const DiscoveredRobot(
          ip: '192.168.10.8',
          serial: '456',
          model: 'WRONG',
        ),
        const DiscoveredRobot(
          ip: '192.168.10.9',
          serial: 'unknown',
          model: 'GRW',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(hub.isLoadingRobots, isFalse);
      final dialog = tester.widget<SelectLaserRobotSettingsDialog>(
        find.byType(SelectLaserRobotSettingsDialog),
      );
      expect(dialog.list.single.serialeRobot, '123-GRW');
      expect(dialog.list.single.ipRobot, '192.168.10.7');
      expect(hub.serverList.first.ipRobot, '10.0.0.99');
      await tester.tap(find.text('123-GRW'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Piano'));
      await tester.pumpAndSettle();
      await selection;
      final controller = hub.laserPages.single.controller;
      addTearDown(controller.onDispose);
      expect(controller.settings.ipRobot, '192.168.10.7');
      expect(controller.settings.ipServer, '10.0.0.100');
      expect(controller.settings.color, '#123456');
      expect(events.last, 'detail:123-GRW');
    },
  );

  testWidgets('no matches keeps the same dialog with its empty state', (
    tester,
  ) async {
    Constants.ROBOT_SEARCH_MODE = 'SCAN';
    final events = <String>[];
    final discovery = _Discovery(events)..result.complete([]);
    final hub = _Hub(discovery, events);
    await _mount(tester, hub);
    final selection = hub.addRobotPressed();
    await tester.pumpAndSettle();
    expect(find.text('Nessun robot disponibile.'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    await selection;
    expect(hub.laserPages, isEmpty);
  });

  testWidgets(
    'disposing while scanning cancels without showing a late dialog',
    (tester) async {
      Constants.ROBOT_SEARCH_MODE = 'SCAN';
      final events = <String>[];
      final discovery = _Discovery(events);
      final hub = _Hub(discovery, events);
      // This test explicitly owns disposal.
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
      final selection = hub.addRobotPressed();
      await tester.pump();
      hub.dispose();
      await tester.pumpAndSettle();
      await selection;
      expect(discovery.isCancelled, isTrue);
      expect(find.byType(SelectLaserRobotSettingsDialog), findsNothing);
      expect(hub.isLoadingRobots, isFalse);
    },
  );
}
