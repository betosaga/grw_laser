import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/laser_page/components/laser_play_pause_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_salda_strato.dart';
import 'package:grw_laser/pages/laser_page/laser_panel_state.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/model/points_free.dart';
import 'package:grw_laser/model/strato_laser.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_parametro.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'support/fake_robot_socket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final controllers = <LaserPageController>[];
  void disposeControllers() {
    for (final c in controllers) {
      c.onDispose();
    }
    controllers.clear();
  }

  setUpAll(() async {
    await Hive.openBox(Constants.HIVE_BOX_NAME, bytes: Uint8List(0));
  });
  setUp(() async => Hive.box(Constants.HIVE_BOX_NAME).clear());
  tearDownAll(Hive.close);

  LaserPageController controller(String serial, {FakeRobotSocket? socket}) {
    final c = LaserPageController(
      hubController: LaserPageHubController(),
      selectedWorkMode: 'piano',
      settings: LaserRobotSettings.fromJson({
        'seriale_robot': serial,
        'ip_robot': '127.0.0.1',
        'color': '#123456',
      }),
      robotSocketConnector: (_, _, _) async => socket ?? FakeRobotSocket(),
    );
    c.mySetState = (callback) => callback?.call();
    c.restoreStratiEseguiti();
    controllers.add(c);
    addTearDown(c.onDispose);
    return c;
  }

  void seedProgress(LaserPageController c, int cordone) {
    c.currentStratiEseguiti![0] = StratoLaser(
      eseguito: true,
      durata: '42',
      lastCordone: cordone,
    );
    c.storeStratiEseguiti();
  }

  Map<String, dynamic> status(int cordone, {String state = 'PAUSED'}) => {
    'f': 'RobotStatus',
    'status': state,
    'lastStrato': 0,
    'lastCordone': cordone,
    'Position': [0, 0, 0, 0, 0, 0],
    'Velocity': [0, 0, 0, 0, 0, 0],
  };

  test('reset and interleaved saves preserve each robot independently', () {
    final first = controller('A');
    seedProgress(first, 8);
    final second = controller('B');
    seedProgress(second, 12);
    // Simulate the stale all-robot snapshot held by already open pages.
    second.stratiEseguiti['A'] = [StratoLaser(eseguito: true, lastCordone: 8)];
    first.stratiEseguiti['B'] = [StratoLaser(lastCordone: 3)];

    first.resetStratiEseguiti();
    seedProgress(second, 15);
    first.storeStratiEseguiti();

    expect(controller('A').currentStratiEseguiti![0].lastCordone, 0);
    final restoredB = controller('B').currentStratiEseguiti![0];
    expect(restoredB.lastCordone, 15);
    expect(restoredB.durata, '42');
    expect(restoredB.eseguito, isTrue);
    expect(controller('C').currentStratiEseguiti, hasLength(10));
  });

  for (final resetMethod in ['resetPunti', 'resetPoints', 'last point']) {
    testWidgets(
      '$resetMethod rejects old progress even after page recreation',
      (tester) async {
        final firstSocket = FakeRobotSocket();
        final secondSocket = FakeRobotSocket();
        final first = controller('A', socket: firstSocket);
        final second = controller('B', socket: secondSocket);
        seedProgress(first, 8);
        seedProgress(second, 12);
        first.points.add(point: Point(x: 1));
        await first.startConnection();
        await second.startConnection();

        switch (resetMethod) {
          case 'resetPunti':
            await first.resetPunti();
          case 'resetPoints':
            await first.resetPoints();
          case 'last point':
            first.removePoint(first.points.points.single);
        }
        first.replacePunti(newPoints: PointsFree(points: [Point(x: 2)]));
        firstSocket.message(status(8));
        firstSocket.message({
          'f': 'WeldInfo',
          'Strato': 0,
          'executionTime': '42',
          'Cordone': 8,
        });
        firstSocket.message({'f': 'Weld', 'Cordone': 8});
        secondSocket.message(status(16));
        await tester.pump();
        expect(first.currentStratiEseguiti![0].lastCordone, 0);
        expect(first.currentStratiEseguiti![0].eseguito, isFalse);
        expect(first.cordone, 0);
        expect(second.currentStratiEseguiti![0].lastCordone, 16);
        second.storeStratiEseguiti();
        first.onDispose();

        final reopenedSocket = FakeRobotSocket();
        final reopened = controller('A', socket: reopenedSocket);
        await reopened.startConnection();
        reopenedSocket.message(status(8, state: 'WELDING'));
        await tester.pump();
        expect(reopened.currentStratiEseguiti![0].lastCordone, 0);
        expect(controller('B').currentStratiEseguiti![0].lastCordone, 16);
        disposeControllers();
      },
    );
  }

  for (final terminalStatus in ['END', 'INACTIVE']) {
    testWidgets('STOP returns to generated path state on $terminalStatus', (
      tester,
    ) async {
      final socket = FakeRobotSocket();
      final c = controller('A', socket: socket);
      final other = controller('B');
      seedProgress(c, 8);
      seedProgress(other, 12);
      c.currentStratiEseguiti![1] = StratoLaser(
        eseguito: true,
        lastCordone: 4,
        durata: '11',
      );
      final generatedPoints = PointsFree(
        points: [Point(x: 0, order: 1), Point(x: 10, order: 2)],
      );
      c.points = generatedPoints;
      c.viewerUrlNotifier.value = 'http://127.0.0.1/viewer';
      c.lastInterpolaResponseNotifier.value = 'generated path';
      c.settings.parametri.addAll([
        for (final key in ['job.start_from_last_weld', 'job.last_weld_index'])
          LaserRobotParametro.fromJson({'parametro': key, 'valore': 0}),
      ]);
      final viewerMessages = <dynamic>[];
      c.webviewDispatchFlutterMessage = (message) async {
        viewerMessages.add(message);
      };
      await c.startConnection();
      socket.message(status(8));
      await tester.pump();
      c.homeReachReceived = true;
      c.armPosition = true;
      c.robotSafePositionFlagNotifier.value = true;
      c.robotSafePositionCurrentRaw = {
        'position': [1, 2, 3, 4, 5, 6],
      };
      final safePosition = c.robotSafePositionCurrentRaw;
      c.cordone = 8;
      c.numerocordonitotale = 20;
      c.totalWeldedLength = 40;
      c.totalWeldingLength = 100;
      c.stopwatch.start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                c.context = context;
                c.mySetState = (callback) => setState(() => callback?.call());
                return Column(
                  children: [
                    LaserSaldaStrato(laserPageController: c),
                    LaserPlayPauseButton(controller: c),
                  ],
                );
              },
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.stop), findsOneWidget);
      final stopping = c.stopCurrentCordone(context: c.context!);
      await tester.pumpAndSettle();
      await tester.tap(find.text('STOP'));
      await tester.pump();
      await stopping;
      expect(socket.writes.map(jsonDecode).last['f'], 'STOPCORDONE');
      expect(c.isStopping, isTrue);
      expect(c.currentStratiEseguiti![0].lastCordone, 8);

      // The terminal packet still carries the previous job's progress.
      socket.message(status(8, state: terminalStatus));
      await tester.pumpAndSettle();
      void expectInitialState() {
        expect(
          c.currentStratiEseguiti!.every(
            (layer) =>
                !layer.eseguito &&
                layer.lastCordone == 0 &&
                layer.durata.isEmpty,
          ),
          isTrue,
        );
        expect(c.weldingStatus, LaserPageController.weldingStatusInactive);
        expect(c.pageState, LaserPanelState.tipoSaldatura);
        expect(c.startedWeldingOnce, isFalse);
        expect(c.stratoCominciato, isFalse);
        expect(c.isStopping, isFalse);
        expect(c.isPausingResuming, isFalse);
        expect(c.pendingRobotTargetStatus, isNull);
        expect(c.cordone, 0);
        expect(c.numerocordonitotale, 0);
        expect(c.totalWeldedLength, 0);
        expect(c.totalWeldingLength, 0);
        expect(c.stopwatch.isRunning, isFalse);
        expect(c.stopwatch.elapsed, Duration.zero);
        expect(find.byIcon(Icons.hourglass_top), findsNothing);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
        expect(find.byIcon(Icons.stop), findsNothing);
        final layerButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Strato\n1'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(layerButton.style!.backgroundColor!.resolve({}), Colors.grey);
      }

      expectInitialState();
      expect(c.points, same(generatedPoints));
      expect(c.viewerUrlNotifier.value, 'http://127.0.0.1/viewer');
      expect(c.lastInterpolaResponseNotifier.value, 'generated path');
      expect(c.robotSafePositionCurrentRaw, same(safePosition));
      expect(viewerMessages.last['executedCordoni'], isEmpty);
      expect(other.currentStratiEseguiti![0].lastCordone, 12);
      expect(controller('B').currentStratiEseguiti![0].lastCordone, 12);
      expect(controller('A').currentStratiEseguiti![1].eseguito, isFalse);

      socket.message(status(8));
      socket.message({
        'f': 'WeldInfo',
        'Strato': 0,
        'executionTime': '42',
        'Cordone': 8,
      });
      socket.message({'f': 'Weld', 'Cordone': 8});
      socket.message({
        'f': 'statusCordoni',
        'Strato': 1,
        'ExecutedCordoni': [
          {'Strato': 1, 'Cordone': 8},
        ],
      });
      await tester.pumpAndSettle();
      expectInitialState();
      expect(viewerMessages.last['executedCordoni'], isEmpty);

      c.onSaldaStratoPressed(0, c.context!);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salda strato 1'));
      await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ero arrivato al cordone'), findsNothing);
      final weld = socket.writes
          .map(jsonDecode)
          .where((message) => message['f'] == 'WELD')
          .single;
      expect(weld['job.start_from_last_weld'], isFalse);
      expect(weld['job.last_weld_index'], 0);
      socket.message(status(0, state: 'WELDING'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.pause), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      disposeControllers();
    });
  }

  for (final action in ['cancel', 'not sent', 'natural end']) {
    testWidgets('$action preserves welding progress', (tester) async {
      final socket = FakeRobotSocket();
      final c = controller('A', socket: socket);
      seedProgress(c, 8);
      await c.startConnection();
      socket.message(status(8));
      await tester.pump();
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
      if (action != 'natural end') {
        final stopping = c.stopCurrentCordone(context: c.context!);
        await tester.pumpAndSettle();
        if (action == 'not sent') c.closeSocket();
        await tester.tap(find.text(action == 'cancel' ? 'ANNULLA' : 'STOP'));
        await tester.pumpAndSettle();
        await stopping;
        expect(c.isStopping, isFalse);
      } else {
        socket.message(status(8, state: 'END'));
        await tester.pump();
      }
      expect(c.currentStratiEseguiti![0].lastCordone, 8);
      expect(c.currentStratiEseguiti![0].eseguito, isTrue);
      expect(
        socket.writes.where((s) => jsonDecode(s)['f'] == 'STOPCORDONE'),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      disposeControllers();
    });
  }

  testWidgets('point synchronization preserves progress for an existing job', (
    tester,
  ) async {
    final socket = FakeRobotSocket();
    final c = controller('A', socket: socket);
    seedProgress(c, 4);
    await c.startConnection();
    socket.message(status(9));
    await tester.pump();
    c.replacePunti(newPoints: PointsFree(points: [Point(x: 1)]));
    expect(c.currentStratiEseguiti![0].lastCordone, 9);
    disposeControllers();
  });

  testWidgets('delete all then WELD starts from zero and tracks the new job', (
    tester,
  ) async {
    final socket = FakeRobotSocket();
    final c = controller('A', socket: socket);
    seedProgress(c, 8);
    c.settings.parametri.addAll([
      for (final key in ['job.start_from_last_weld', 'job.last_weld_index'])
        LaserRobotParametro.fromJson({'parametro': key, 'valore': 0}),
    ]);
    c.points.add(point: Point(x: 1));
    await c.startConnection();
    c.homeReachReceived = true;
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

    final deletion = c.deleteAllPoints(context: c.context!);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await deletion;
    expect(c.points.isEmpty, isTrue);
    c.replacePunti(
      newPoints: PointsFree(
        points: [Point(x: 0, order: 1), Point(x: 10, order: 2)],
      ),
    );
    c.armPosition = true;
    c.robotSafePositionFlagNotifier.value = true;
    c.robotSafePositionCurrentRaw = {
      'position': [1, 2, 3, 4, 5, 6],
    };
    socket.message(status(8));
    await tester.pump();

    c.onSaldaStratoPressed(0, c.context!);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salda strato 1'));
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Ero arrivato al cordone'), findsNothing);
    final weld = socket.writes
        .map(jsonDecode)
        .where((message) => message['f'] == 'WELD')
        .single;
    expect(weld['job.start_from_last_weld'], isFalse);
    expect(weld['job.last_weld_index'], 0);

    // The previous job can still be reported while the new request is pending.
    socket.message(status(8));
    await tester.pump();
    expect(c.currentStratiEseguiti![0].lastCordone, 0);
    // The start transition itself may still carry the previous lastCordone.
    socket.message(status(8, state: 'WELDING'));
    await tester.pump();
    expect(c.currentStratiEseguiti![0].lastCordone, 0);
    socket.message(status(2, state: 'WELDING'));
    await tester.pump();
    expect(c.currentStratiEseguiti![0].lastCordone, 2);

    c.onSaldaStratoPressed(0, c.context!);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salda strato 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ero arrivato al cordone 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    disposeControllers();
  });
}
