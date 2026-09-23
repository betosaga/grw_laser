import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_parametro.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_robot_socket.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('grw-cloud-');
    Hive.init(hiveDirectory.path);
    await Hive.openBox(Constants.HIVE_BOX_NAME);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  for (final command in ['interpola', 'WELD']) {
    for (final missingCurve in [
      null,
      'base',
      'limite',
      'unnumbered base',
      'unnumbered limite',
      'unnumbered both',
    ]) {
      testWidgets(
        '$command validates cloud points (invalid assignment: $missingCurve)',
        (tester) async {
          final socket = FakeRobotSocket();
          final c = LaserPageController(
            hubController: LaserPageHubController(),
            selectedWorkMode: 'controrotaiasemplice',
            settings: LaserRobotSettings(
              serialeRobot: 'CLOUD-TEST',
              ipRobot: '127.0.0.1',
              ipServer: '127.0.0.2',
              pinGas: '1',
              pinLaser: '3',
              pinMassa: '4',
              color: '',
              parametri: [
                for (final key in [
                  'path.base_points',
                  'path.point_order',
                  'path.perimeter_order',
                  'path.base_curve_indices',
                  'path.limit_curve_indices',
                ])
                  LaserRobotParametro.fromJson({
                    'parametro': key,
                    'tipo': 'json',
                    'valore': [],
                  }),
              ],
            ),
            robotSocketConnector: (_, _, _) async => socket,
          );
          addTearDown(c.onDispose);
          c.mySetState = (callback) => callback?.call();
          c.armPosition = true;
          c.robotSafePositionFlagNotifier.value = true;
          c.robotSafePositionCurrentRaw = {
            'position': [1, 2, 3, 4, 5, 6],
          };
          c.modalitaNuvolaNotifier.value = true;
          final selected = List.generate(
            4,
            (i) => Point(x: i.toDouble(), order: i + 1)
              ..isBase = i < 2 && missingCurve != 'base'
              ..isLimite = i >= 2 && missingCurve != 'limite',
          );
          // Free points are interspersed with an unsorted perimeter.
          final free = Point(x: 99, dashboardPosition: const Offset(10, 20));
          final hasUnnumberedCurvePoint =
              missingCurve?.startsWith('unnumbered') ?? false;
          final originalPoints = [
            free,
            selected[3],
            selected[1],
            Point(x: 100),
            selected[0],
            selected[2],
            if (hasUnnumberedCurvePoint)
              Point(x: 101)
                ..isBase = missingCurve != 'unnumbered limite'
                ..isLimite = missingCurve != 'unnumbered base',
          ];
          c.points.points = originalPoints.toList();
          expect(c.areCloudCurvePointsOrdered, !hasUnnumberedCurvePoint);
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

          final payloads = <Map<String, dynamic>>[];
          if (command == 'interpola') {
            await tester.runAsync(
              () => http.runWithClient(
                () => c.sendPointsToFastAPI(),
                () => MockClient((request) async {
                  expect(request.url.path, '/interpola_nuvola');
                  payloads.add(
                    jsonDecode(request.body) as Map<String, dynamic>,
                  );
                  return http.Response(
                    jsonEncode({
                      'ok': true,
                      'index': 0,
                      'log_file': '',
                      'grafico_file': '',
                      'plot_json': '',
                      'meta_json': '',
                      'viewer_url': '/viewer',
                      'script': '',
                    }),
                    200,
                  );
                }),
              ),
            );
          } else {
            await c.startConnection();
            c.homeReachReceived = true;
            c.initializeStratiEseguiti();
            await tester.runAsync(() async {
              c.onSaldaStratoPressed(0, c.context!);
            });
            await tester.pumpAndSettle();
            await tester.tap(find.text('Salda strato 1'));
            await tester.runAsync(() async {
              await Future<void>.delayed(Duration.zero);
              await Hive.box(Constants.HIVE_BOX_NAME).flush();
            });
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));
            payloads.addAll(
              socket.writes
                  .map((body) => jsonDecode(body) as Map<String, dynamic>)
                  .where((payload) => payload['f'] == 'WELD'),
            );
          }

          if (missingCurve == null) {
            expect(payloads, hasLength(1));
            final payload = payloads.single;
            expect(payload['path.base_points'], [
              for (var i = 0; i < 4; i++) [i, 0, 0, 0, 0, 0],
            ]);
            expect(payload['path.point_order'], [0, 1, 2, 3]);
            expect(payload['path.perimeter_order'], [0, 1, 2, 3]);
            expect(payload['path.base_curve_indices'], [0, 1]);
            expect(payload['path.limit_curve_indices'], [2, 3]);
          } else {
            expect(payloads, isEmpty);
            if (hasUnnumberedCurvePoint) {
              await tester.pump();
              expect(
                find.text(
                  'Assegna un numero di perimetro a tutti i punti BASE e LIMITE',
                ),
                findsOneWidget,
              );
            }
          }
          expect(c.points.points, orderedEquals(originalPoints));
          expect(free.order, isNull);
          expect(free.isBase, isFalse);
          expect(free.isLimite, isFalse);
          expect(free.dashboardPosition, const Offset(10, 20));
          expect(selected.map((p) => p.order), [1, 2, 3, 4]);
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          c.onDispose();
        },
      );
    }
  }
}
