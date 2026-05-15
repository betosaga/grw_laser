import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/components/laser_rectangle_with_cross_cursor.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserPositionDashboard extends StatelessWidget {
  final LaserPageController controller;

  LaserPositionDashboard({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(
            child: LaserRectangleWithCrossCursor(
              key: ValueKey(controller.dashboardResetVersion),
              controller: controller,
              scaleX: 1,
              scaleZ: 2.5,
              posizioneRobot: controller.posizioneRobot,
              robotSpeed: controller.robotSpeed,
              stopwatch: controller.stopwatch,
              paused: controller.paused,
            ),
          ),
        ],
      ),
    );
  }
}
