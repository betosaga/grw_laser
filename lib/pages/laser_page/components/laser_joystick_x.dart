import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/components/laser_continuous_press_button.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:unicons/unicons.dart';

class LaserJoystickX extends StatelessWidget {
  final LaserPageController controller;
  LaserJoystickX({required this.controller});

  String _stepLabel(double value) => value.toStringAsFixed(1);

  Future<void> onButtonXPressed(double value) async {
    if (controller.socket == null) return;
    final isPiano = controller.isPianoRotolamento;
    await controller.sendJoystickMoveCommand(
      {
        "f": "MOVE",
        "deltax": "0",
        "deltay": isPiano ? "0" : value.toStringAsFixed(1),
        "deltaz": isPiano ? (-value).toStringAsFixed(1) : "0",
        "deltaj6": "0",
      },
      ignoredLog: 'Ignoro Joystick X',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPiano = controller.isPianoRotolamento;
    final stepUp =
        isPiano ? controller.effectiveStepUp : controller.effectiveStepY;
    final stepDown =
        isPiano ? controller.effectiveStepDown : controller.effectiveStepY;
    final upLimited =
        isPiano ? controller.isStepUpLimited : controller.isStepYLimited;
    final downLimited =
        isPiano ? controller.isStepDownLimited : controller.isStepYLimited;

    return Container(
        padding: EdgeInsets.all(20),
        child: GridView.count(
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 1,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            children: [
              ContinuousPressButton.LaserContinuousPressButton(
                icon: UniconsLine.arrow_up,
                onPressed: () => onButtonXPressed(-1 * stepUp),
                radius: BorderRadius.all(Radius.circular(8)),
                locked: false,
                limited: upLimited,
                stepLabel: _stepLabel(stepUp),
                showLabelOnTop: true,
              ),
              ContinuousPressButton.LaserContinuousPressButton(
                icon: UniconsLine.arrow_down,
                onPressed: () => onButtonXPressed(1 * stepDown),
                radius: BorderRadius.all(Radius.circular(8)),
                locked: false,
                limited: downLimited,
                stepLabel: _stepLabel(stepDown),
                showLabelOnTop: true,
              ),
            ]));
  }
}
