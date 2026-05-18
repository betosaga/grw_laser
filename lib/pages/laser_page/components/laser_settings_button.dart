import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserSettingsButton extends StatelessWidget {
  final LaserPageController controller;
  const LaserSettingsButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => Vibrator.shortVibration(),
      child: TextButton(
        onPressed: () => controller.openSettingsPage(context: context),
        child: Icon(
          Icons.settings,
          color: Colors.white,
        )),
    );
  }
}
