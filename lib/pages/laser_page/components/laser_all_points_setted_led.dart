import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserAllPointsSettedLED extends StatelessWidget {
  final LaserPageController controller;
  const LaserAllPointsSettedLED({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Container(
          width: 24,
          height: 24,
        ));
  }
}
