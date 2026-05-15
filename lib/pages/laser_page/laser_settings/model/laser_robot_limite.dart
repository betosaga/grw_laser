import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';

class LaserRobotLimite {
  //
  //
  //
  final int? id;
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
  //
  //
  //
  const LaserRobotLimite({
    this.id,
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
  });
  //
  //
  //
  factory LaserRobotLimite.fromJson(Map<String, dynamic> json) {
    return LaserRobotLimite(
      id: LaserRobotSettings.nullableInt(json['id']),
      limiteZDown: LaserRobotSettings.intOrDefault(json['limite_z_down']),
      stepUp: LaserRobotSettings.doubleOrDefault(json['step_up']),
      stepDown: LaserRobotSettings.doubleOrDefault(json['step_down']),
      stepUpSx: LaserRobotSettings.doubleOrDefault(json['step_up_sx']),
      stepUpDx: LaserRobotSettings.doubleOrDefault(json['step_up_dx']),
      stepDownSx: LaserRobotSettings.doubleOrDefault(json['step_down_sx']),
      stepDownDx: LaserRobotSettings.doubleOrDefault(json['step_down_dx']),
      stepLeft: LaserRobotSettings.doubleOrDefault(json['step_left']),
      stepRight: LaserRobotSettings.doubleOrDefault(json['step_right']),
      stepY: LaserRobotSettings.doubleOrDefault(json['step_y']),
      tipoControrotaia:
          LaserRobotSettings.stringOrEmpty(json['tipo_controrotaia']),
    );
  }
  //
  //
  //
  Map<String, dynamic> toJson() {
    //
    //
    //
    return {
      if (id != null) 'id': id,
      'limite_z_down': limiteZDown,
      'step_up': stepUp,
      'step_down': stepDown,
      'step_up_sx': stepUpSx,
      'step_up_dx': stepUpDx,
      'step_down_sx': stepDownSx,
      'step_down_dx': stepDownDx,
      'step_left': stepLeft,
      'step_right': stepRight,
      'step_y': stepY,
      'tipo_controrotaia': tipoControrotaia,
    };
  }
  //
  //
  //
}