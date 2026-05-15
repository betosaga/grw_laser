import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserClosePageButton extends StatelessWidget {
  final LaserPageHubController controller;
  LaserClosePageButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => Vibrator.shortVibration(),
      child: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        onPressed: () => controller.closePage(context: context),
        color: Colors.white,
      ),
    );
  }
}
