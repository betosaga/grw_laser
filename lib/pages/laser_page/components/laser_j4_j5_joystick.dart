import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/components/laser_continuous_press_button.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:unicons/unicons.dart';

class LaserJ4J5Joystick extends StatelessWidget {
  final LaserPageController controller;
  //
  //
  LaserJ4J5Joystick({required this.controller});
  //
  //
  Future<void> onButtonJ5Pressed(double delta) async {
    if (controller.socket == null) return;
    await controller.sendJoystickMoveCommand(
      {
        "f": "MOVERX",
        "deltarx": "0",
        "deltary": delta.toStringAsFixed(1),
        "deltarz": "0",
      },
      ignoredLog: 'Ignoro Joystick J5',
    );
  }
  //
  //
  Future<void> onButtonJ4Pressed(double delta) async {
    if (controller.socket == null) return;
    await controller.sendJoystickMoveCommand(
      {
        "f": "MOVERX",
        "deltarx": delta.toStringAsFixed(1),
        "deltary": "0",
        "deltarz": "0",
      },
      ignoredLog: 'Ignoro Joystick J4',
    );
  }
  //
  //
  @override
  Widget build(BuildContext context) {
    //
    //
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              width: 64,
              child: ContinuousPressButton.LaserContinuousPressButton(
                icon: UniconsLine.arrow_left,
                onPressed: () => onButtonJ5Pressed(1 * controller.step / 3),
                radius: BorderRadius.all(Radius.circular(8)),
                locked: false,
                stepLabel: 'j5+',
                showLabelOnTop: true,
              ),
            ),
            SizedBox(width: 28),
            SizedBox(
              height: 64,
              width: 64,
              child: ContinuousPressButton.LaserContinuousPressButton(
                icon: UniconsLine.arrow_right,
                onPressed: () => onButtonJ5Pressed(-1 * controller.step / 3),
                radius: BorderRadius.all(Radius.circular(8)),
                locked: false,
                stepLabel: 'j5-',
                showLabelOnTop: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              width: 64,
              child: ContinuousPressButton.LaserContinuousPressButton(
                icon: UniconsLine.arrow_left,
                onPressed: () => onButtonJ4Pressed(1 * controller.step / 3),
                radius: BorderRadius.all(Radius.circular(8)),
                locked: false,
                stepLabel: 'j4+',
                showLabelOnTop: true,
              ),
            ),
            SizedBox(width: 28),
            SizedBox(
              height: 64,
              width: 64,
              child: ContinuousPressButton.LaserContinuousPressButton(
                icon: UniconsLine.arrow_right,
                onPressed: () => onButtonJ4Pressed(-1 * controller.step / 3),
                radius: BorderRadius.all(Radius.circular(8)),
                locked: false,
                stepLabel: 'j4-',
                showLabelOnTop: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
  //
  //
}
