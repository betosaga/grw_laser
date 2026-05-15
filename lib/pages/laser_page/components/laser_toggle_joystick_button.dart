import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserToggleJoystickButton extends StatelessWidget {
  final LaserPageController controller;
  const LaserToggleJoystickButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => Vibrator.shortVibration(),
      child: IconButton(
        icon: Icon(Icons.api_sharp),
        onPressed: controller.toggleJoystick,
        color: Colors.white,
      ),
    );
  }
}
