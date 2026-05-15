import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserLogButton extends StatelessWidget {
  final LaserPageController controller;
  LaserLogButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => Vibrator.shortVibration(),
      child: TextButton(
        onPressed: controller.toggleLog,
        child: Icon(
          Icons.terminal,
          color: controller.showLogWindow ? Colors.green : Colors.white,
        )),
    );
  }
}
