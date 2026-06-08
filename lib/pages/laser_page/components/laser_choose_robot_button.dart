import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserChooseRobotButton extends StatelessWidget {
  final LaserPageHubController controller;
  const LaserChooseRobotButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => Vibrator.shortVibration(),
      child: TextButton(
          onPressed: controller.isLoadingRobots
              ? () {}
              : controller.selectRobotPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(56, 56),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: controller.isLoadingRobots
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ))
              : Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 36,
                )),
    );
  }
}
