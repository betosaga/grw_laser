import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/services/color_service.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';

class SelectLaserRobotSettingsDialog extends StatelessWidget {
  final List<LaserRobotSettings> list;

  const SelectLaserRobotSettingsDialog({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text("Selezione robot"),
        content: Text(""),
        actions: list
          .map<Widget>((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Listener(
                    onPointerDown: (_) => Vibrator.shortVibration(),
                    child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorService.hexToColor(e.color),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Pager.pop(context, e),
                    child: Text(
                      e.serialeRobot,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ),
                )))
            .toList()
          ..add(Listener(
            onPointerDown: (_) => Vibrator.shortVibration(),
            child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.sagaBlue,
            ),
            onPressed: () => Pager.pop(context, null),
            child: Text(
              "Annulla",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sagaBlue),
            ),
          ))),
    );
  }
}
