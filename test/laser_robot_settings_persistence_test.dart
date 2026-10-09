import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/response/response_error.dart';
import 'package:grw_laser/pages/laser_page/laser_page.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/components/laser_robot_setting_row.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/laser_robot_parametri_page.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/laser_settings_page.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_robot_socket.dart';

Map<String, dynamic> initialSettings() => {
  'seriale_robot': 'TEST',
  'ip_robot': '127.0.0.1',
  'ip_server': '127.0.0.2:8000',
  'pin_gas': '1',
  'pin_laser': '3',
  'pin_massa': '4',
  'allontanamento_x': 0,
  'allontanamento_y': 0,
  'allontanamento_z': 0,
  'parametri': [
    for (final entry in {
      'network.fastapi.host': ['string', '127.0.0.2:8000'],
      'network.fastapi.port': ['int', 8000],
      'path.weld_width_mm': ['double', 3.5],
    }.entries)
      {
        'parametro': entry.key,
        'tipo': entry.value[0],
        'valore': entry.value[1],
        'valore_default': entry.value[1],
        'categoria': 'Test',
        'modificabile': true,
      },
  ],
};

LaserPageController controller(Map<String, dynamic> settings) {
  final hub = LaserPageHubController();
  final result = LaserPageController(
    hubController: hub,
    settings: LaserRobotSettings.fromJson(settings),
    selectedWorkMode: 'controrotaiasemplice',
    robotSocketConnector: (_, _, _) async => FakeRobotSocket(),
  );
  result.mySetState = (callback) => callback?.call();
  hub.laserPages.add(LaserPage(controller: result));
  addTearDown(result.onDispose);
  return result;
}

void main() {
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('grw-settings-test-');
    Hive.init(directory.path);
    await Hive.openBox(Constants.HIVE_BOX_NAME);
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('IP server displays and saves the stored port 8824', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = initialSettings();
    data['ip_server'] = '192.168.10.13:8824';
    (data['parametri'] as List).first['valore'] = '192.168.10.13';
    final c = controller(data);
    expect(c.effectiveServerAddress, '192.168.10.13:8824');
    expect(c.serverBaseUrl, 'http://192.168.10.13:8824');
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(home: LaserSettingsPage(laserPageController: c)),
        );
        final field = find.descendant(
          of: find.widgetWithText(LaserRobotSettingRow, 'IP SERVER: '),
          matching: find.byType(TextFormField),
        );
        expect(
          tester.widget<TextFormField>(field).controller!.text,
          '192.168.10.13:8824',
        );
        final save = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'SALVA'),
        );
        await tester.runAsync(
          () async => await Function.apply(save.onPressed!, const []),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextFormField>(field).controller!.text,
          '192.168.10.13:8824',
        );
        expect(c.settings.ipServer, '192.168.10.13:8824');
        expect(c.robotParametroValue('network.fastapi.port'), 8824);
        final restored = controller(c.settings.toJson());
        expect(restored.serverBaseUrl, 'http://192.168.10.13:8824');
      },
      () => MockClient((request) async {
        expect(request.bodyFields['ip_server'], '192.168.10.13:8824');
        final parameters = jsonDecode(request.bodyFields['parametri']!) as List;
        expect(
          parameters,
          contains(
            equals({'parametro': 'network.fastapi.port', 'valore': 8824}),
          ),
        );
        for (final row in data['parametri'] as List) {
          for (final updated in parameters) {
            if (row['parametro'] == updated['parametro'])
              row['valore'] = updated['valore'];
          }
        }
        return http.Response(jsonEncode(data), 200);
      }),
    );
  });

  test(
    'separate port edits update the full address and survive reload',
    () async {
      final data = initialSettings();
      final c = controller(data);
      c.updateRobotParametroValue('network.fastapi.port', 8824);
      expect(c.serverBaseUrl, 'http://127.0.0.2:8824');
      await http.runWithClient(
        () async {
          await c.saveRobotSettings();
        },
        () => MockClient((request) async {
          expect(request.bodyFields['ip_server'], '127.0.0.2:8824');
          data['ip_server'] = '127.0.0.2:8824';
          (data['parametri'] as List)[1]['valore'] = 8824;
          return http.Response(jsonEncode(data), 200);
        }),
      );
      expect(c.isRobotParametroDirty('network.fastapi.port'), isFalse);
      expect(c.serverBaseUrl, 'http://127.0.0.2:8824');
      expect(
        controller(c.settings.toJson()).serverBaseUrl,
        'http://127.0.0.2:8824',
      );
    },
  );

  for (final allParameters in [false, true]) {
    testWidgets('save, reconnect and restore (all parameters=$allParameters)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var server = initialSettings();
      final c = controller(server);
      final requests = <Map<String, String>>[];
      const address = '192.168.1.42:9001';

      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: allParameters
                  ? LaserRobotParametriPage(laserPageController: c)
                  : LaserSettingsPage(laserPageController: c),
            ),
          );
          if (allParameters) {
            await tester.tap(find.text('Test'));
            await tester.pumpAndSettle();
            for (final entry in {
              'network.fastapi.host': address,
              'network.fastapi.port': '9001',
              'path.weld_width_mm': '4.5',
            }.entries) {
              final field = find.descendant(
                of: find
                    .ancestor(
                      of: find.text(entry.key),
                      matching: find.byType(Card),
                    )
                    .first,
                matching: find.byType(TextFormField),
              );
              await tester.ensureVisible(field);
              await tester.enterText(field, entry.value);
            }
          } else {
            final field = find.descendant(
              of: find.widgetWithText(LaserRobotSettingRow, 'IP SERVER: '),
              matching: find.byType(TextFormField),
            );
            await tester.enterText(field, address);
          }
          final save = tester.widget<TextButton>(
            find.widgetWithText(TextButton, 'SALVA'),
          );
          await tester.runAsync(() async {
            await Function.apply(save.onPressed!, const []);
          });
          await tester.pumpAndSettle();

          expect(requests, hasLength(1));
          expect(requests.single['ip_server'], address);
          expect(c.settings.ipServer, address);
          expect(c.robotParametroValue('network.fastapi.host'), address);
          expect(c.isRobotParametroDirty('network.fastapi.host'), isFalse);
          expect(
            find.text(
              allParameters
                  ? 'Parametri salvati correttamente'
                  : 'Impostazioni salvate correttamente',
            ),
            findsOneWidget,
          );
          if (allParameters) {
            expect(c.robotParametroValue('network.fastapi.port'), 9001);
            expect(c.robotParametroValue('path.weld_width_mm'), 4.5);
          }

          await c.startConnection();
          c.closeSocket();
          await c.startConnection();
          expect(c.robotParametroValue('network.fastapi.host'), address);
          final reloaded = await c.hubController.fetchRobotDetail(
            serialeRobot: 'TEST',
          );
          expect(reloaded!.ipServer, address);
          final stored = robotLaserSettingsListFromJson(
            Hive.box(
                  Constants.HIVE_BOX_NAME,
                ).get(Constants.HIVE_LASER_SETTINGS_LIST_KEY)
                as String,
          );
          expect(stored.single.ipServer, address);
          final restored = controller(stored.single.toJson());
          expect(restored.robotParametroValue('network.fastapi.host'), address);
          if (allParameters) {
            expect(restored.robotParametroValue('network.fastapi.port'), 9001);
            expect(restored.robotParametroValue('path.weld_width_mm'), 4.5);
          }
          c.onDispose();
          restored.onDispose();
        },
        () => MockClient((request) async {
          final fields = request.bodyFields;
          if (fields['f'] == 'setImpostazioniRobotLaser') {
            requests.add(fields);
            final parameters = jsonDecode(fields['parametri']!) as List;
            server = {
              ...server,
              for (final key in initialSettings().keys)
                if (fields.containsKey(key) && key != 'parametri')
                  key: fields[key],
              'parametri': [
                for (final parameter in server['parametri'] as List)
                  {
                    ...parameter as Map<String, dynamic>,
                    for (final updated in parameters)
                      if (updated['parametro'] == parameter['parametro'])
                        'valore': updated['valore'],
                  },
              ],
            };
          }
          return http.Response(jsonEncode(server), 200);
        }),
      );
    });
  }

  for (final failure in ['http', 'stale', 'missing']) {
    test('failed save keeps changes pending ($failure)', () async {
      final original = initialSettings();
      final c = controller(original);
      c.hubController.storeSettingsListToDisk();
      final before = Hive.box(
        Constants.HIVE_BOX_NAME,
      ).get(Constants.HIVE_LASER_SETTINGS_LIST_KEY);
      c.updateRobotParametroValue('network.fastapi.host', '192.168.1.42:9001');
      await http.runWithClient(
        () async {
          await expectLater(
            c.saveRobotSettings(),
            throwsA(isA<ResponseError>()),
          );
        },
        () => MockClient((_) async {
          if (failure == 'http') {
            return http.Response(
              jsonEncode({'code': 1, 'message': 'Errore'}),
              400,
            );
          }
          return http.Response(
            jsonEncode({
              ...original,
              if (failure == 'missing') ...{
                'ip_server': '192.168.1.42:9001',
                'parametri': [],
              },
            }),
            200,
          );
        }),
      );
      expect(c.isRobotParametroDirty('network.fastapi.host'), isTrue);
      expect(
        c.robotParametroValue('network.fastapi.host'),
        '192.168.1.42:9001',
      );
      expect(
        Hive.box(
          Constants.HIVE_BOX_NAME,
        ).get(Constants.HIVE_LASER_SETTINGS_LIST_KEY),
        before,
      );
    });
  }

  for (final confirmed in [false, true]) {
    test(
      'base settings without cached catalog (confirmed=$confirmed)',
      () async {
        final c = controller({...initialSettings(), 'parametri': []});
        const address = '192.168.1.42:9001';
        await http.runWithClient(
          () async {
            final save = c.saveRobotSettings(fields: {'ip_server': address});
            if (confirmed) {
              await save;
              expect(c.settings.ipServer, address);
              expect(c.robotParametroValue('network.fastapi.host'), address);
            } else {
              await expectLater(save, throwsA(isA<ResponseError>()));
              expect(c.settings.ipServer, '127.0.0.2:8000');
            }
          },
          () => MockClient((request) async {
            expect(request.bodyFields['ip_server'], address);
            final response = initialSettings();
            response['ip_server'] = address;
            if (confirmed) {
              (response['parametri'] as List).first['valore'] = address;
            }
            return http.Response(jsonEncode(response), 200);
          }),
        );
      },
    );
  }
}
