import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_robot_socket.dart';

const speedKey = 'motion.weld.speed_mm_s';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Hive.openBox(Constants.HIVE_BOX_NAME, bytes: Uint8List(0));
  });
  setUp(() async => Hive.box(Constants.HIVE_BOX_NAME).clear());
  tearDownAll(Hive.close);

  LaserPageController controller(
    String serial, {
    dynamic defaultSpeed = 12.5,
    FakeRobotSocket? socket,
  }) {
    final c = LaserPageController(
      hubController: LaserPageHubController(),
      selectedWorkMode: 'piano',
      settings: LaserRobotSettings.fromJson({
        'seriale_robot': serial,
        'ip_robot': '127.0.0.1',
        'ip_server': '127.0.0.2',
        'color': '#123456',
        'parametri': [
          if (defaultSpeed != null)
            {
              'parametro': speedKey,
              'tipo': 'double',
              'valore': defaultSpeed,
              'modificabile': true,
            },
        ],
      }),
      robotSocketConnector: (_, _, _) async => socket ?? FakeRobotSocket(),
    );
    c.mySetState = (callback) => callback?.call();
    addTearDown(c.onDispose);
    return c;
  }

  testWidgets('startup seeds local layer speeds and edits remain per robot', (
    tester,
  ) async {
    final first = controller('A');
    final second = controller('B', defaultSpeed: '7.25');
    first.onInit();
    second.onInit();
    await tester.pump();
    await tester.pump();
    expect(first.velocitasaldatura, List.filled(10, 12.5));
    expect(
      first.velocitaSaldaturaController.map((input) => input.text),
      everyElement('12.5'),
    );
    expect(second.velocitasaldatura, List.filled(10, 7.25));

    first.velocitaSaldaturaController[1].text = '4,75';
    first.velocitaSaldaturaController[9].text = '18.5';
    expect(first.velocitasaldatura, [
      12.5,
      4.75,
      ...List.filled(7, 12.5),
      18.5,
    ]);
    expect(first.velocitaSaldaturaController[0].text, '12.5');
    expect(second.velocitasaldatura, List.filled(10, 7.25));
    expect(first.robotParametroValue(speedKey), 12.5);
    expect(first.isRobotParametroDirty(speedKey), isFalse);
    expect(first.dirtyRobotParametriPayload(), isEmpty);

    // Reopening the robot seeds from the DB default, not the previous edits.
    final reopened = controller('A');
    expect(reopened.velocitasaldatura, List.filled(10, 12.5));
    first.onDispose();
    second.onDispose();
    reopened.onDispose();
  });

  testWidgets('saving settings neither sends nor clears local speed edits', (
    tester,
  ) async {
    final c = controller('A');
    c.velocitaSaldaturaController[2].text = '42.25';
    final databaseSettings = c.settings.toJson();
    final requests = <Map<String, String>>[];
    await tester.runAsync(
      () => http.runWithClient(
        () => c.saveRobotSettings(),
        () => MockClient((request) async {
          requests.add(request.bodyFields);
          return http.Response(jsonEncode(databaseSettings), 200);
        }),
      ),
    );
    expect(requests, hasLength(1));
    expect(requests.single['f'], 'setImpostazioniRobotLaser');
    expect(requests.single.containsKey('parametri'), isFalse);
    expect(requests.single.containsKey(speedKey), isFalse);
    expect(requests.single.values, isNot(contains('42.25')));
    expect(c.robotParametroValue(speedKey), 12.5);
    expect(c.velocitasaldatura[2], 42.25);
    expect(c.velocitaSaldaturaController[2].text, '42.25');
    expect(c.isRobotParametroDirty(speedKey), isFalse);
    c.onDispose();
  });

  for (final configured in [true, false]) {
    testWidgets('WELD sends selected layer speed (DB parameter=$configured)', (
      tester,
    ) async {
      final socket = FakeRobotSocket();
      final c = controller(
        'A',
        defaultSpeed: configured ? 12.5 : null,
        socket: socket,
      );
      await c.startConnection();
      c.homeReachReceived = true;
      c.armPosition = true;
      c.robotSafePositionFlagNotifier.value = true;
      c.robotSafePositionCurrentRaw = {
        'position': [1, 2, 3, 4, 5, 6],
      };
      c.initializeStratiEseguiti();
      c.points.points = [Point(x: 0, order: 1), Point(x: 10, order: 2)];
      c.velocitaSaldaturaController[0].text = '4.75';
      c.velocitaSaldaturaController[3].text = '8.5';
      c.velocitaSaldaturaController[9].text = '16.25';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                c.context = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      for (final layer in [0, 3, 9]) {
        c.onSaldaStratoPressed(layer, c.context!);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salda strato ${layer + 1}'));
        await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
      }
      final payloads = socket.writes
          .map(jsonDecode)
          .where((message) => message['f'] == 'WELD')
          .toList();
      expect(payloads.map((payload) => payload[speedKey]), [4.75, 8.5, 16.25]);
      expect(c.robotParametroValue(speedKey), configured ? 12.5 : null);
      expect(c.isRobotParametroDirty(speedKey), isFalse);
      expect(c.velocitasaldatura[0], 4.75);
      expect(c.velocitasaldatura[3], 8.5);
      expect(c.velocitasaldatura[9], 16.25);
      await tester.pumpWidget(const SizedBox());
      c.onDispose();
    });
  }
}
