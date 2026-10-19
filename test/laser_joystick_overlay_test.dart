import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_responsive_framework/flutter_responsive_framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/pages/laser_page/components/laser_continuous_press_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_joystick.dart';
import 'package:grw_laser/pages/laser_page/components/laser_joystick_dashboard.dart';
import 'package:grw_laser/pages/laser_page/components/laser_viewer_webview.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_panel_state.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'support/fake_robot_socket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Hive.openBox(Constants.HIVE_BOX_NAME, bytes: Uint8List(0));
  });
  tearDownAll(Hive.close);

  for (final size in [const Size(1600, 1000), const Size(1000, 1600)]) {
    testWidgets('joystick overlay routes moves to its robot at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final sockets = [FakeRobotSocket(), FakeRobotSocket()];
      final controllers = List.generate(2, (index) {
        final c = LaserPageController(
          hubController: LaserPageHubController(),
          selectedWorkMode: 'piano',
          settings: LaserRobotSettings.fromJson({
            'seriale_robot': 'ROBOT-$index',
            'ip_robot': '127.0.0.1',
            'color': '#123456',
          }),
          robotSocketConnector: (_, _, _) async => sockets[index],
        );
        c.mySetState = (callback) => callback?.call();
        addTearDown(c.onDispose);
        return c;
      });
      for (final c in controllers) {
        await c.startConnection();
      }
      final c = controllers.first;
      c.pageState = LaserPanelState.tipoSaldatura;
      c.sendingSimulationNotifier.value = true;
      c.points.add(point: Point(x: 12, order: 1));
      final points = c.points;
      await tester.pumpWidget(
        ResponsiveUIWidget(
          builder: (_, _, _) => MaterialApp(
            home: Scaffold(body: LaserViewerWebview(controller: c)),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getCenter(find.text('Joystick')).dx,
        lessThan(tester.getCenter(find.text('Prendi punti')).dx),
      );
      await tester.tap(find.text('Joystick'));
      await tester.pump();
      expect(find.byType(LaserJoystickDashboard), findsOneWidget);
      expect(find.text('Joystick · ROBOT-0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // A modal overlay covers the page, including the underlying robot tabs.
      expect(tester.getSize(find.byWidgetPredicate(
                (widget) => widget is ModalBarrier && widget.color == Colors.black54)), size);

      await tester.tap(find.text('5'));
      await tester.pump();
      final movementButtons = find.descendant(
        of: find.byType(LaserJoystick),
        matching: find.byType(ContinuousPressButton),
      );
      c.canMoveRobot = true;
      await tester.tap(movementButtons.at(1));
      await tester.pump();
      final move = jsonDecode(sockets.first.writes.single);
      expect(move['f'], 'MOVE');
      expect(move['deltay'], '-5.0');
      expect(sockets.last.writes, isEmpty);
      expect(c.pageState, LaserPanelState.tipoSaldatura);
      expect(c.points, same(points));
      expect(controllers.last.step, 10);

      await tester.tap(find.text('Chiudi'));
      await tester.pump();
      expect(find.byType(LaserJoystickDashboard), findsNothing);
      expect(find.text('Prendi punti'), findsOneWidget);
      expect(c.pageState, LaserPanelState.tipoSaldatura);
      await tester.tap(find.text('Joystick'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(LaserJoystickDashboard), findsNothing);
      expect(find.byType(LaserViewerWebview), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      for (final c in controllers) {
        c.onDispose();
      }
    });
  }
}
