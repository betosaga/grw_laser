import 'dart:convert';

import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_limite.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_parametro.dart';

LaserRobotSettings robotLaserSettingsFromJson(String str) =>
    LaserRobotSettings.fromJson(json.decode(str));
String robotLaserSettingsToJson(LaserRobotSettings data) =>
    json.encode(data.toJson());
List<LaserRobotSettings> robotLaserSettingsListFromJson(String str) =>
    List<LaserRobotSettings>.from(
        json.decode(str).map((x) => LaserRobotSettings.fromJson(x)));
String robotLaserSettingsListToJson(List<LaserRobotSettings> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));



//
//
//
class LaserRobotSettings {
  final String serialeRobot;
  final String ipRobot;
  final String ipServer;
  final String pinGas;
  final String pinLaser;
  final String pinMassa;
  final int scostamentoX;
  final int scostamentoY;
  final int scostamentoZ;
  final String color;
  final int limiteZDown;
  final double stepUp;
  final double stepDown;
  final double stepUpSx;
  final double stepUpDx;
  final double stepDownSx;
  final double stepDownDx;
  final double stepLeft;
  final double stepRight;
  final double stepY;
  final String tipoControrotaia;
  final List<LaserRobotLimite> limiti;
  final List<LaserRobotParametro> parametri;

  LaserRobotSettings(
      {required this.serialeRobot,
      required this.ipRobot,
      required this.ipServer,
      required this.pinGas,
      required this.pinLaser,
      required this.pinMassa,
      this.scostamentoX = 0,
      this.scostamentoY = 0,
      this.scostamentoZ = 0,
      required this.color,
      this.limiteZDown = 0,
      this.stepUp = 0,
      this.stepDown = 0,
      this.stepUpSx = 0,
      this.stepUpDx = 0,
      this.stepDownSx = 0,
      this.stepDownDx = 0,
      this.stepLeft = 0,
      this.stepRight = 0,
      this.stepY = 0,
      this.tipoControrotaia = '0',
      this.limiti = const [],
      this.parametri = const []});

  static String stringOrEmpty(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int intOrDefault(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static int? nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double doubleOrDefault(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    final normalized = value.toString().replaceAll(',', '.');
    return double.tryParse(normalized) ?? defaultValue;
  }

  factory LaserRobotSettings.fromJson(Map<String, dynamic> json) =>
      _fromJson(json);

  static LaserRobotSettings _fromJson(Map<String, dynamic> json) {
    final rawLimiti = json['limiti'];
    List<LaserRobotLimite> parsedLimiti = [];
    if (rawLimiti is List) {
      parsedLimiti = rawLimiti
          .whereType<Map>()
          .map((e) => LaserRobotLimite.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final rawParametri = json['parametri'];
    List<LaserRobotParametro> parsedParametri = [];
    if (rawParametri is List) {
      parsedParametri = rawParametri
          .whereType<Map>()
          .map((e) => LaserRobotParametro.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Backward compatibility: if no list is provided, fallback to flat fields.
    if (parsedLimiti.isEmpty) {
      parsedLimiti = [
        LaserRobotLimite(
          limiteZDown: intOrDefault(json['limite_z_down']),
          stepUp: doubleOrDefault(json['step_up']),
          stepDown: doubleOrDefault(json['step_down']),
          stepUpSx: doubleOrDefault(json['step_up_sx']),
          stepUpDx: doubleOrDefault(json['step_up_dx']),
          stepDownSx: doubleOrDefault(json['step_down_sx']),
          stepDownDx: doubleOrDefault(json['step_down_dx']),
          stepLeft: doubleOrDefault(json['step_left']),
          stepRight: doubleOrDefault(json['step_right']),
          stepY: doubleOrDefault(json['step_y']),
          tipoControrotaia: stringOrEmpty(json['tipo_controrotaia']),
        )
      ];
    }

    final first = parsedLimiti.first;
    return LaserRobotSettings(
      serialeRobot: stringOrEmpty(json['seriale_robot']),
      ipRobot: stringOrEmpty(json['ip_robot']),
      ipServer: stringOrEmpty(json['ip_server']),
      pinGas: stringOrEmpty(json['pin_gas']),
      pinLaser: stringOrEmpty(json['pin_laser']),
      pinMassa: stringOrEmpty(json['pin_massa']),
      scostamentoX: intOrDefault(json['allontanamento_x']),
      scostamentoY: intOrDefault(json['allontanamento_y']),
      scostamentoZ: intOrDefault(json['allontanamento_z']),
      color: stringOrEmpty(json['color']),
      limiteZDown: first.limiteZDown,
      stepUp: first.stepUp,
      stepDown: first.stepDown,
      stepUpSx: first.stepUpSx,
      stepUpDx: first.stepUpDx,
      stepDownSx: first.stepDownSx,
      stepDownDx: first.stepDownDx,
      stepLeft: first.stepLeft,
      stepRight: first.stepRight,
      stepY: first.stepY,
      tipoControrotaia: first.tipoControrotaia,
      limiti: parsedLimiti,
      parametri: parsedParametri,
    );
  }

  Map<String, dynamic> toJson() => {
        "seriale_robot": serialeRobot,
        "ip_robot": ipRobot,
        "ip_server": ipServer,
        "pin_gas": pinGas,
        "pin_laser": pinLaser,
        "pin_massa": pinMassa,
        "allontanamento_x": scostamentoX,
        "allontanamento_y": scostamentoY,
        "allontanamento_z": scostamentoZ,
        "color": color,
        "limite_z_down": limiteZDown,
        "step_up": stepUp,
        "step_down": stepDown,
        "step_up_sx": stepUpSx,
        "step_up_dx": stepUpDx,
        "step_down_sx": stepDownSx,
        "step_down_dx": stepDownDx,
        "step_left": stepLeft,
        "step_right": stepRight,
        "step_y": stepY,
        "tipo_controrotaia": tipoControrotaia,
        "limiti": List<dynamic>.from(limiti.map((x) => x.toJson())),
        "parametri": List<dynamic>.from(parametri.map((x) => x.toJson())),
      };
}
