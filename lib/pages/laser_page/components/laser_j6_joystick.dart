import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/components/laser_continuous_press_button.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';
import 'package:unicons/unicons.dart';

class LaserJ6Joystick extends StatelessWidget {
  final LaserPageController controller;
  LaserJ6Joystick({required this.controller});

  final double iconSize = 58;

  Future<void> onButtonJ6Pressed(double delta) async {
    if (controller.socket == null) return;
    await controller.sendJoystickMoveCommand(
      {
        "f": "MOVERX",
        "deltarx": "0",
        "deltary": "0",
        "deltarz": delta.toStringAsFixed(1),
      },
      ignoredLog: 'Ignoro Joystick J6',
    );
  }

  Future<void> centerTorchPressed() async {
    if (controller.socket == null) return;
    await controller.sendJoystickMoveCommand(
      {
        "f": "CENTERTORCH",
      },
      ignoredLog: 'Ignoro Joystick J6',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTapDown: (_) => Vibrator.shortVibration(),
          onTap: centerTorchPressed,
          child: SvgPicture.asset(
            width: iconSize,
            height: iconSize,
            "images/grw-arm-icon.svg",
            colorFilter:
                const ColorFilter.mode(AppColors.sagaBlue, BlendMode.srcIn),
          ),
        ),
        Row(
          children: [
            SizedBox(
              height: 64,
              width: 64,
              child: ContinuousPressButton.LaserContinuousPressButton(
                icon: UniconsLine.arrow_left,
                onPressed: () => onButtonJ6Pressed(1 * controller.step / 3),
                radius: BorderRadius.all(Radius.circular(8)),
                locked: false,
                stepLabel: 'j6+',
                showLabelOnTop: true,
              ),
            ),
            SizedBox(
              width: 28,
            ),
            SizedBox(
              height: 64,
              width: 64,
              child: ContinuousPressButton.LaserContinuousPressButton(
                icon: UniconsLine.arrow_right,
                onPressed: () => onButtonJ6Pressed(-1 * controller.step / 3),
                radius: BorderRadius.all(Radius.circular(8)),
                locked: false,
                stepLabel: 'j6-',
                showLabelOnTop: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
