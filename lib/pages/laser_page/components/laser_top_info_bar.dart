import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserTopInfoBar extends StatelessWidget {
  final LaserPageController controller;

  const LaserTopInfoBar({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: AppColors.sagaBlue,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Text("Model: ${controller.robotModelRead}",
                style: TextStyle(color: Colors.white)),
            Spacer(),
            Text(
                "Cordone " +
                    controller.cordone.toString() +
                    " (Start cordone: " +
                    controller.cordoneiniziale.toString() +
                    ", End cordone: " +
                    controller.cordonefinale.toString() +
                    ")" +
                    " - MAX num cordoni: " +
                    controller.numerocordonitotale.toString() +
                    (controller.frameSet
                        ? " - Frame (mm): ${controller.frameWidth} x ${controller.frameHeight}"
                        : ""),
                style: TextStyle(color: Colors.white)),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
