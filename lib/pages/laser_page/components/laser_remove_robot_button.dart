import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserRemoveRobotButton extends StatelessWidget {
  final LaserPageController controller;
  const LaserRemoveRobotButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isRemoving = controller.isRemovingRobotPage;

    return TextButton(
      onPressed: isRemoving
          ? null
          : () async {
              Vibrator.shortVibration();
              await controller.removeRobotPage();
            },
      onLongPress: isRemoving
          ? null
          : () async {
              Vibrator.longVibration();
              await controller.removeRobotPage();
            },
      child: isRemoving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.delete,
              color: Colors.white,
            ),
    );
  }
}
