import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/laser_robot_parametri_page.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_parametro.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';

LaserRobotParametro _parametro(String key, dynamic value,
    {String tipo = 'double', bool modificabile = true}) {
  return LaserRobotParametro(
    parametro: key,
    tipo: tipo,
    nullable: true,
    valore: value,
    valoreDefault: value,
    valoriAmmessi: null,
    categoria: 'Test',
    descrizione: null,
    ordine: 0,
    modificabile: modificabile,
    personalizzato: false,
  );
}

LaserPageController _controller(List<LaserRobotParametro> parametri) {
  final controller = LaserPageController(
    hubController: LaserPageHubController(),
    settings: LaserRobotSettings(
      serialeRobot: 'TEST',
      ipRobot: '127.0.0.1',
      ipServer: '127.0.0.1',
      pinGas: '1',
      pinLaser: '3',
      pinMassa: '4',
      color: '',
      parametri: parametri,
    ),
  );
  controller.mySetState = (callback) => callback?.call();
  return controller;
}

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('grw-laser-test-');
    Hive.init(hiveDirectory.path);
    await Hive.openBox(Constants.HIVE_BOX_NAME);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('il valore parametro condiviso alimenta payload e dirty state', () {
    final width = _parametro('path.weld_width_mm', 3.0);
    final controller = _controller([width]);

    controller.updateRobotParametroValue('path.weld_width_mm', 4.5);

    expect(width.valore, 4.5);
    expect(controller.robotParametroValue('path.weld_width_mm'), 4.5);
    expect(controller.larghezzaCordone.text, '4.5');
    expect(controller.isRobotParametroDirty('path.weld_width_mm'), isTrue);
    expect(controller.dirtyRobotParametriPayload(), [
      {'parametro': 'path.weld_width_mm', 'valore': 4.5}
    ]);
  });

  test('punti e ordine si sincronizzano in entrambe le direzioni', () {
    final basePoints = _parametro(
      'path.base_points',
      <dynamic>[],
      tipo: 'array',
    );
    final pointOrder = _parametro(
      'path.point_order',
      <dynamic>[],
      tipo: 'array<int>',
    );
    final baseIndices = _parametro(
      'path.base_curve_indices',
      <dynamic>[],
      tipo: 'array<int>',
    );
    final limitIndices = _parametro(
      'path.limit_curve_indices',
      <dynamic>[],
      tipo: 'array<int>',
    );
    final perimeterOrder = _parametro(
      'path.perimeter_order',
      <dynamic>[],
      tipo: 'array<int>',
    );
    final controller = _controller([
      basePoints,
      pointOrder,
      perimeterOrder,
      baseIndices,
      limitIndices,
    ]);

    controller.updateRobotParametroValue('path.point_order', [0, 1]);
    controller.updateRobotParametroValue('path.base_curve_indices', [0]);
    controller.updateRobotParametroValue('path.limit_curve_indices', [1]);
    controller.updateRobotParametroValue('path.base_points', [
      [1, 2, 3, 4, 5, 6],
      [7, 8, 9, 10, 11, 12],
    ]);

    expect(basePoints.valore, hasLength(2));
    expect(controller.points.points, hasLength(2));
    expect(controller.points.points.first.x, 1);
    expect(controller.points.points.first.order, 0);
    expect(controller.points.points.first.isBase, isTrue);
    expect(controller.points.points.last.isLimite, isTrue);

    controller.points.points.first.x = 42;
    controller.notifyPointsOrderChanged();

    expect((basePoints.valore as List).first.first, 42);
    expect(pointOrder.valore, [0, 1]);
    expect(
      controller.dirtyRobotParametriPayload(),
      contains(equals({'parametro': 'path.point_order', 'valore': [0, 1]})),
    );
  });

  testWidgets('il campo array<int> aggiorna il payload come lista', (tester) async {
    final pointOrder = _parametro('path.point_order', [0, 1], tipo: 'array<int>');
    final controller = _controller([pointOrder]);
    await tester.pumpWidget(MaterialApp(
      home: LaserRobotParametriPage(laserPageController: controller),
    ));
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();

    expect(find.text('Inserisci JSON valido'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '[1,0]');

    expect(pointOrder.valore, [1, 0]);
    expect(controller.dirtyRobotParametriPayload(), [
      {'parametro': 'path.point_order', 'valore': [1, 0]},
    ]);
    await tester.enterText(find.byType(TextFormField), '[invalid');
    expect(pointOrder.valore, [1, 0]);
    await tester.pumpAndSettle();
  });
}
