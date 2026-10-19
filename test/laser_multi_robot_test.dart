import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_responsive_framework/flutter_responsive_framework.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/laser_page/laser_page.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'support/fake_robot_socket.dart';

LaserRobotSettings _settings(int id) => LaserRobotSettings.fromJson({
  'seriale_robot': 'ROBOT-$id',
  'ip_robot': '192.168.10.$id',
  'color': '#123456',
  'modalita_abilitate': [
    {'codice': 'piano', 'nome': 'Piano'},
  ],
});

class _Hub extends LaserPageHubController {
  @override
  Future<void> fetchRobotList() async {
    elencoRobotSettings = [_settings(1), _settings(2), _settings(3)];
  }

  @override
  Future<LaserRobotSettings?> fetchRobotDetail({
    required String serialeRobot,
  }) async => _settings(int.parse(serialeRobot.split('-').last));

  @override
  void storeSettingsListToDisk() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.openBox(Constants.HIVE_BOX_NAME, bytes: Uint8List(0));
  });
  tearDownAll(Hive.close);

  Future<void> mount(WidgetTester tester, _Hub hub) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async => const StandardMessageCodec().encodeMessage([null]),
        );
    await tester.pumpWidget(
      ResponsiveUIWidget(
        builder: (_, _, _) => MaterialApp(home: LaserPageHub(controller: hub)),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'switching pages keeps all sockets and routes messages independently',
    (tester) async {
      final hub = _Hub();
      final sockets = List.generate(3, (_) => FakeRobotSocket());
      final controllers = List.generate(
        3,
        (i) => LaserPageController(
          hubController: hub,
          settings: _settings(i + 1),
          selectedWorkMode: 'piano',
          robotSocketConnector: (_, _, _) async => sockets[i],
        ),
      );
      for (final c in controllers) {
        // Exercise the actual page lifecycle without unrelated startup settings.
        c.initialized = true;
        hub.laserPages.add(LaserPage(key: ObjectKey(c), controller: c));
        addTearDown(c.onDispose);
      }
      await mount(tester, hub);
      for (var i = 0; i < controllers.length; i++) {
        hub.pageController.jumpToPage(i);
        await tester.pump();
        await controllers[i].startConnection();
        await tester.pump();
      }
      expect(controllers.every((c) => !c.isDisposing), isTrue);
      expect(sockets.every((s) => !s.destroyed), isTrue);

      sockets[0].message({'f': 'RobotStatus', 'status': 'PAUSED'});
      sockets[1].message({'f': 'RobotStatus', 'status': 'WELDING'});
      await tester.pump();
      expect(controllers[0].weldingStatus, 'PAUSED');
      expect(controllers[1].weldingStatus, 'WELDING');
      await controllers[0].sendMessageToRobot({'f': 'PAUSE'});
      expect(sockets[0].writes.map(jsonDecode).single['f'], 'PAUSE');
      expect(sockets[1].writes, isEmpty);
      expect(sockets[2].writes, isEmpty);

      hub.pageController.jumpToPage(0);
      await tester.pump();
      expect(controllers[0].socket, same(sockets[0]));

      final remainingStates = [
        tester.state(
          find.byKey(ObjectKey(controllers[1]), skipOffstage: false),
        ),
        tester.state(
          find.byKey(ObjectKey(controllers[2]), skipOffstage: false),
        ),
      ];
      final removal = hub.removePageFor(robotSerial: 'ROBOT-1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('ELIMINA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(await removal, isTrue);
      expect(sockets[0].destroyed, isTrue);
      expect(controllers[0].isDisposing, isTrue);
      expect(hub.laserPages.map((p) => p.controller), controllers.skip(1));
      for (var i = 1; i < controllers.length; i++) {
        hub.pageController.jumpToPage(i - 1);
        await tester.pump();
        expect(controllers[i].socket, same(sockets[i]));
        expect(sockets[i].destroyed, isFalse);
        expect(
          tester.state(find.byKey(ObjectKey(controllers[i]))),
          same(remainingStates[i - 1]),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(sockets.every((s) => s.destroyed), isTrue);
    },
  );

  testWidgets(
    'plus opens each newly added robot after the page list is laid out',
    (tester) async {
      final previousMode = Constants.ROBOT_SEARCH_MODE;
      addTearDown(() => Constants.ROBOT_SEARCH_MODE = previousMode);
      Constants.ROBOT_SEARCH_MODE = 'FLAT';
      final hub = _Hub();
      await mount(tester, hub);
      for (var i = 1; i <= 3; i++) {
        final selection = hub.addRobotPressed();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('ROBOT-$i'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Piano'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        await selection;
        expect(hub.laserPages, hasLength(i));
        expect(hub.currentIndex, i - 1);
        expect(hub.laserPages.every((p) => !p.controller.isDisposing), isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
