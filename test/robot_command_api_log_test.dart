import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/configuration/urls.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_parametro.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'support/fake_robot_socket.dart';

class _TrackedClient extends MockClient {
  _TrackedClient(super.handler);
  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

LaserPageController _controller(FakeRobotSocket socket) {
  final c = LaserPageController(
    hubController: LaserPageHubController(),
    settings: LaserRobotSettings(
      serialeRobot: 'ROBOT-TEST',
      ipRobot: '127.0.0.1',
      ipServer: '127.0.0.2',
      pinGas: '1',
      pinLaser: '3',
      pinMassa: '4',
      color: '',
      parametri: [
        LaserRobotParametro.fromJson({
          'parametro': 'path.base_points',
          'tipo': 'json',
          'valore': [],
        }),
        LaserRobotParametro.fromJson({
          'parametro': 'debug.extra',
          'tipo': 'json',
          'valore': {'null': null, 'enabled': false, 'label': 'prova è & +'},
        }),
      ],
    ),
    robotSocketConnector: (_, _, _) async => socket,
  );
  c.mySetState = (callback) => callback?.call();
  addTearDown(c.onDispose);
  return c;
}

void main() {
  late Directory hiveDirectory;
  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('grw-command-log-');
    Hive.init(hiveDirectory.path);
    await Hive.openBox(Constants.HIVE_BOX_NAME);
  });
  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets(
    'WELD logs the full socket payload without awaiting API response',
    (tester) async {
      final socket = FakeRobotSocket();
      final c = _controller(socket);
      final apiResponse = Completer<http.Response>();
      final requests = <http.Request>[];
      await http.runWithClient(
        () async {
          await c.startConnection();
          final payload = {
            'f': 'WELD',
            'path.base_points': List.generate(2000, (i) => [i, 1.5, null]),
            'safeposition': {
              'orientation': 'DX',
              'position': [1, 2, 3, 4, 5, 6],
            },
            'custom': {'enabled': false, 'label': 'prova è & +'},
          };
          final receipt = await c.sendMessageToRobot(payload);
          await tester.pump();
          expect(receipt.accepted, isTrue);
          expect(apiResponse.isCompleted, isFalse);
          expect(socket.writes, hasLength(1));
          expect(requests, hasLength(1));
          expect(requests.single.url, URLs.apiurl);
          final form = requests.single.bodyFields;
          expect(form['f'], 'logRobotLaserCommand');
          expect(form['comando'], 'WELD');
          expect(form['seriale_robot'], 'ROBOT-TEST');
          expect(form['destinazione'], 'tcp://127.0.0.1:20002');
          expect(form['stato_invio'], 'socket_write_attempted');
          expect(form['parametri_json'], socket.writes.single);
          expect(form['id_comando'], '${receipt.id}');
          expect(form['sessione_robot'], '${receipt.session}');
          expect(DateTime.parse(form['dataora_client']!).isUtc, isTrue);
          (payload['custom'] as Map)['label'] = 'changed later';
          expect(
            jsonDecode(form['parametri_json']!)['custom']['label'],
            'prova è & +',
          );
          apiResponse.complete(http.Response('{"message":"ok"}', 200));
          await tester.pump();
          expect(c.logString, contains('richiesta registrata'));
          c.onDispose();
        },
        () => MockClient((request) {
          requests.add(request);
          return apiResponse.future;
        }),
      );
    },
  );

  testWidgets(
    'rejected WELD is logged as not sent; API error cannot reconnect',
    (tester) async {
      final socket = FakeRobotSocket();
      final c = _controller(socket);
      final requests = <http.Request>[];
      await http.runWithClient(
        () async {
          final receipt = await c.sendMessageToRobot({
            'f': 'WELD',
            'value': null,
          });
          await tester.pump();
          expect(receipt.accepted, isFalse);
          expect(requests.single.bodyFields['stato_invio'], 'not_sent');
          expect(c.logString, contains('registrazione fallita'));
          await c.startConnection();
          expect(socket.writes, isEmpty);
          expect(c.connectionStatus, isTrue);
          c.onDispose();
        },
        () => MockClient((request) async {
          requests.add(request);
          throw const SocketException('logging API unavailable');
        }),
      );
    },
  );

  testWidgets('API timeout closes only the HTTP client, not the robot socket', (
    tester,
  ) async {
    final socket = FakeRobotSocket();
    final c = _controller(socket);
    final response = Completer<http.Response>();
    final client = _TrackedClient((_) => response.future);
    await http.runWithClient(() async {
      await c.startConnection();
      final session = c.robotSession;
      await c.sendMessageToRobot({'f': 'WELD'});
      await tester.pump(const Duration(seconds: 11));
      expect(client.closed, isTrue);
      expect(socket.destroyed, isFalse);
      expect(c.robotSession, session);
      expect(c.connectionStatus, isTrue);
      expect(c.logString, contains('registrazione fallita'));
      expect(socket.writes, hasLength(1));
      c.onDispose();
      response.complete(http.Response('{}', 200));
      await tester.pump();
    }, () => client);
  });

  for (final cloud in [false, true]) {
    testWidgets(
      'interpola (cloud=$cloud) logs the exact HTTP body and endpoint',
      (tester) async {
        final c = _controller(FakeRobotSocket());
        c.armPosition = true;
        c.robotSafePositionFlagNotifier.value = true;
        c.robotSafePositionCurrentRaw = {
          'position': [1, 2, 3, 4, 5, 6],
        };
        c.modalitaNuvolaNotifier.value = cloud;
        c.points.points = List.generate(
          4,
          (i) => Point(x: i.toDouble(), order: i)
            ..isBase = i < 2
            ..isLimite = i >= 2,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                c.context = context;
                return const SizedBox();
              },
            ),
          ),
        );
        final requests = <http.Request>[];
        await http.runWithClient(
          () async {
            await c.sendPointsToFastAPI();
            await tester.pump();
          },
          () => MockClient((request) async {
            requests.add(request);
            // API errors must not prevent the real interpolation request.
            if (request.url == URLs.apiurl) {
              return http.Response(
                '{"code":1,"message":"log unavailable"}',
                500,
              );
            }
            return http.Response('simulated interpolation error', 500);
          }),
        );
        expect(requests, hasLength(2));
        final api = requests.singleWhere((r) => r.url == URLs.apiurl);
        final interpolation = requests.singleWhere((r) => r.url != URLs.apiurl);
        expect(
          interpolation.url.path,
          cloud ? '/interpola_nuvola' : '/interpola',
        );
        expect(api.bodyFields['comando'], '/interpola');
        expect(api.bodyFields['destinazione'], interpolation.url.toString());
        expect(api.bodyFields['parametri_json'], interpolation.body);
        final payload = jsonDecode(interpolation.body);
        expect(payload['path.base_points'], hasLength(4));
        expect(payload['debug.extra']['null'], isNull);
        expect(payload['debug.extra']['label'], 'prova è & +');
        expect(c.logString, contains('registrazione fallita'));
        expect(c.logString, contains('log unavailable'));
        c.onDispose();
      },
    );
  }
}
