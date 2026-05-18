import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';
import 'package:unicons/unicons.dart';

class LaserConnectionButtons extends StatelessWidget {
  final LaserPageController controller;
  const LaserConnectionButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: controller.connectionStatus
            ? TextButton(
                onPressed: null,
                onLongPress: () {
                  Vibrator.mediumVibration();
                  controller.disconnectRobot();
                },
                child: Icon(
                  UniconsLine.bolt,
                  size: 32,
                  color: Colors.white,
                ))
            : TextButton(
                onPressed: null,
                onLongPress: () {
                  Vibrator.mediumVibration();
                  controller.connettiRobot();
                },
                child: Icon(
                  UniconsLine.bolt_slash,
                  size: 32,
                  color: Colors.white,
                )));
  }
}
