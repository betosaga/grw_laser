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

const baseKeys = ['ip_robot', 'ip_server', 'pin_gas', 'pin_laser', 'pin_massa'];

Map<String, dynamic> initialSettings() => {
  'seriale_robot': 'TEST',
  'ip_robot': '192.168.10.12',
  'ip_server': '192.168.10.13',
  'pin_gas': '1',
  'pin_laser': '3',
  'pin_massa': '4',
  'allontanamento_x': 0,
  'allontanamento_y': 0,
  'allontanamento_z': 0,
  'parametri': [
    for (final entry in {
      'network.fastapi.host': ['string', '10.99.0.10:9000'],
      'network.fastapi.port': ['int', 9001],
      'io.gas_output_pin': ['int', 71],
      'io.laser_output_pin': ['int', 73],
      'io.mass_output_pin': ['int', 74],
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

// Two tables with a one-way copy on base saves, like the PHP endpoint tests.
class SettingsServer {
  final data = initialSettings();
  final requests = <Map<String, String>>[];
  Future<http.Response> handle(http.Request request) async {
    final fields = request.bodyFields;
    requests.add(fields);
    switch (fields['f']) {
      case 'setImpostazioniRobotLaser':
        expect(fields.containsKey('parametri'), isFalse);
        for (final key in [
          ...baseKeys,
          'allontanamento_x',
          'allontanamento_y',
          'allontanamento_z',
        ]) {
          data[key] = fields[key];
        }
        for (final row in data['parametri'] as List) {
          switch (row['parametro']) {
            case 'network.fastapi.host':
              row['valore'] = data['ip_server'];
              break;
            case 'io.gas_output_pin':
              row['valore'] = int.parse(data['pin_gas'] as String);
              break;
            case 'io.laser_output_pin':
              row['valore'] = int.parse(data['pin_laser'] as String);
              break;
            case 'io.mass_output_pin':
              row['valore'] = int.parse(data['pin_massa'] as String);
              break;
          }
        }
        break;
      case 'setParametriRobotLaser':
        for (final key in baseKeys) {
          expect(fields.containsKey(key), isFalse);
        }
        for (final updated in jsonDecode(fields['parametri']!) as List) {
          for (final row in data['parametri'] as List) {
            if (row['parametro'] == updated['parametro']) {
              row['valore'] = updated['valore'];
            }
          }
        }
        break;
      case 'getRobotLaserDetail':
      case 'getImpostazioniRobotLaser':
        break;
      default:
        fail('Unexpected endpoint: ${fields['f']}');
    }
    return http.Response(jsonEncode(data), 200);
  }
}

Finder baseField(String key) {
  if (key == 'ip_robot') return find.byType(TextFormField).first;
  const labels = {
    'ip_server': 'IP SERVER: ',
    'pin_gas': 'PIN GAS: ',
    'pin_laser': 'PIN LASER: ',
    'pin_massa': 'PIN MASSA: ',
  };
  return find.descendant(
    of: find.widgetWithText(LaserRobotSettingRow, labels[key]!),
    matching: find.byType(TextFormField),
  );
}

Future<void> invokeButton(WidgetTester tester, Finder finder) async {
  final button = tester.widget<TextButton>(finder);
  await tester.runAsync(
    () async => await Function.apply(button.onPressed!, const []),
  );
  await tester.pumpAndSettle();
}

void largeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

  for (final address in ['192.168.10.13', '192.168.10.13:8824', '']) {
    testWidgets('base fields use only ROBOT_LASER: $address', (tester) async {
      largeScreen(tester);
      final server = SettingsServer();
      server.data['ip_server'] = address;
      final c = controller(server.data);
      // Pending catalog edits must neither fill nor get saved by the base form.
      c.updateRobotParametroValue('network.fastapi.host', '10.98.0.10:9900');
      c.updateRobotParametroValue('io.gas_output_pin', 81);
      c.updateRobotParametroValue('path.weld_width_mm', 4.5);
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(home: LaserSettingsPage(laserPageController: c)),
        );
        for (final key in baseKeys) {
          expect(
            tester.widget<TextFormField>(baseField(key)).controller!.text,
            server.data[key],
          );
        }
        final values = {
          'ip_robot': '192.168.10.14',
          'ip_server': address,
          'pin_gas': '2',
          'pin_laser': '5',
          'pin_massa': '6',
        };
        for (final entry in values.entries) {
          await tester.enterText(baseField(entry.key), entry.value);
        }
        // Typing in the base fields must not update catalog values either.
        expect(
          c.robotParametroValue('network.fastapi.host'),
          '10.98.0.10:9900',
        );
        expect(c.robotParametroValue('io.gas_output_pin'), 81);
        await invokeButton(tester, find.widgetWithText(TextButton, 'SALVA'));
        expect(server.requests.single['f'], 'setImpostazioniRobotLaser');
        for (final entry in values.entries) {
          expect(server.data[entry.key], entry.value);
          expect(c.settings.toJson()[entry.key], entry.value);
          expect(
            tester.widget<TextFormField>(baseField(entry.key)).controller!.text,
            entry.value,
          );
        }
        for (final entry in {
          'network.fastapi.host': address,
          'io.gas_output_pin': 2,
          'io.laser_output_pin': 5,
          'io.mass_output_pin': 6,
          'network.fastapi.port': 9001,
        }.entries) {
          expect(c.robotParametroValue(entry.key), entry.value);
          expect(c.isRobotParametroDirty(entry.key), isFalse);
        }
        expect(c.robotParametroValue('path.weld_width_mm'), 4.5);
        expect(c.isRobotParametroDirty('path.weld_width_mm'), isTrue);
        final stored = robotLaserSettingsListFromJson(
          Hive.box(
                Constants.HIVE_BOX_NAME,
              ).get(Constants.HIVE_LASER_SETTINGS_LIST_KEY)
              as String,
        ).single;
        for (final entry in values.entries) {
          expect(stored.toJson()[entry.key], entry.value);
        }
        expect(
          stored.parametri
              .singleWhere((row) => row.parametro == 'network.fastapi.host')
              .valore,
          address,
        );
        await c.startConnection();
        c.closeSocket();
        await c.startConnection();
        expect(c.settings.ipServer, address);
        c.onDispose();
      }, () => MockClient(server.handle));
    });
  }

  testWidgets(
    'server refresh uses raw base values, including empty IP server',
    (tester) async {
      largeScreen(tester);
      final server = SettingsServer();
      final c = controller(server.data);
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(home: LaserSettingsPage(laserPageController: c)),
        );
        server.data['ip_server'] = '';
        server.data['pin_gas'] = '9';
        await invokeButton(
          tester,
          find.widgetWithIcon(TextButton, Icons.update),
        );
        expect(c.settings.ipServer, '');
        expect(
          tester.widget<TextFormField>(baseField('ip_server')).controller!.text,
          '',
        );
        expect(
          tester.widget<TextFormField>(baseField('pin_gas')).controller!.text,
          '9',
        );
        expect(c.robotParametroValue('io.gas_output_pin'), 71);
      }, () => MockClient(server.handle));
    },
  );

  testWidgets(
    'all parameters save only the catalog; base fields stay unchanged',
    (tester) async {
      largeScreen(tester);
      final server = SettingsServer();
      final c = controller(server.data);
      final before = {for (final key in baseKeys) key: server.data[key]};
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(home: LaserRobotParametriPage(laserPageController: c)),
        );
        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();
        for (final entry in {
          'network.fastapi.host': '10.98.0.10:9900',
          'io.gas_output_pin': '81',
        }.entries) {
          final field = find.descendant(
            of: find
                .ancestor(of: find.text(entry.key), matching: find.byType(Card))
                .first,
            matching: find.byType(TextFormField),
          );
          await tester.ensureVisible(field);
          await tester.enterText(field, entry.value);
        }
        await invokeButton(tester, find.widgetWithText(TextButton, 'SALVA'));
        expect(server.requests.single['f'], 'setParametriRobotLaser');
        expect(
          c.robotParametroValue('network.fastapi.host'),
          '10.98.0.10:9900',
        );
        expect(c.robotParametroValue('io.gas_output_pin'), 81);
        expect(c.robotParametroValue('network.fastapi.port'), 9001);
        expect(c.isRobotParametroDirty('network.fastapi.host'), isFalse);
        await tester.pumpWidget(
          MaterialApp(home: LaserSettingsPage(laserPageController: c)),
        );
        await tester.pumpAndSettle();
        for (final entry in before.entries) {
          expect(server.data[entry.key], entry.value);
          expect(c.settings.toJson()[entry.key], entry.value);
          expect(
            tester.widget<TextFormField>(baseField(entry.key)).controller!.text,
            entry.value,
          );
        }
        final reloaded = await c.hubController.fetchRobotDetail(
          serialeRobot: 'TEST',
        );
        expect(reloaded!.ipServer, before['ip_server']);
      }, () => MockClient(server.handle));
    },
  );

  for (final parameterForm in [false, true]) {
    for (final failure in ['http', 'stale', if (!parameterForm) 'uncopied']) {
      test(
        'failed save keeps prior state (parameters=$parameterForm, $failure)',
        () async {
          final original = initialSettings();
          final c = controller(original);
          c.hubController.storeSettingsListToDisk();
          final before = Hive.box(
            Constants.HIVE_BOX_NAME,
          ).get(Constants.HIVE_LASER_SETTINGS_LIST_KEY);
          c.updateRobotParametroValue(
            'network.fastapi.host',
            '10.98.0.10:9900',
          );
          await http.runWithClient(
            () async {
              await expectLater(
                parameterForm
                    ? c.saveRobotSettings(
                        parametri: c.dirtyRobotParametriPayload(),
                      )
                    : c.saveRobotSettings(
                        fields: {'ip_server': '192.168.10.13:8824'},
                      ),
                throwsA(isA<ResponseError>()),
              );
            },
            () => MockClient(
              (_) async => failure == 'http'
                  ? http.Response(
                      jsonEncode({'code': 1, 'message': 'Errore'}),
                      400,
                    )
                  : http.Response(
                      jsonEncode({
                        ...original,
                        if (failure == 'uncopied')
                          'ip_server': '192.168.10.13:8824',
                      }),
                      200,
                    ),
            ),
          );
          expect(c.settings.ipServer, original['ip_server']);
          expect(c.isRobotParametroDirty('network.fastapi.host'), isTrue);
          expect(
            Hive.box(
              Constants.HIVE_BOX_NAME,
            ).get(Constants.HIVE_LASER_SETTINGS_LIST_KEY),
            before,
          );
        },
      );
    }
  }
}
