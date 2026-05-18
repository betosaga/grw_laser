import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/components/laser_continuous_press_button.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:unicons/unicons.dart';

class LaserJoystick extends StatelessWidget {
  final LaserPageController controller;
  const LaserJoystick({super.key, required this.controller});

  String _stepLabel(double value) => value.toStringAsFixed(1);

  Future<void> onButtonPressed(double deltax, deltay, deltaz) async {
    await controller.sendJoystickMoveCommand(
      {
        "f": "MOVE",
        "deltax": deltax.toStringAsFixed(1),
        "deltay": deltay.toStringAsFixed(1),
        "deltaz": deltaz.toStringAsFixed(1),
        "deltaj6": "0",
      },
      ignoredLog: 'Ignoro Joystick',
    );
  }

  Future<void> onGoToHomePressed() async {
    await controller.sendJoystickMoveCommand(
      {"f": "GOTOHOME"},
      ignoredLog: 'Ignoro Joystick',
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepUpSx = controller.effectiveStepUpSx;
    final stepUp = controller.effectiveStepUp;
    final stepUpDx = controller.effectiveStepUpDx;
    final stepLeft = controller.effectiveStepLeft;
    final stepRight = controller.effectiveStepRight;
    final stepDownSx = controller.effectiveStepDownSx;
    final stepDown = controller.effectiveStepDown;
    final stepDownDx = controller.effectiveStepDownDx;

    return Container(
      color: Colors.transparent,
      child: GridView.count(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        shrinkWrap: true,
        children: [
          ContinuousPressButton.LaserContinuousPressButton(
            icon: UniconsLine.arrow_up_left,
            onPressed: controller.verticalLock
                ? () {}
                : () => onButtonPressed(1 * stepUpSx, 0, 1 * stepUpSx),
            radius: BorderRadius.only(topLeft: Radius.circular(20)),
            locked: controller.verticalLock,
            limited: controller.isStepUpSxLimited,
            stepLabel: _stepLabel(stepUpSx),
            showLabelOnTop: false,
          ),
          ContinuousPressButton.LaserContinuousPressButton(
            icon: UniconsLine.arrow_up,
            onPressed: () => controller.isPianoRotolamento
                ? onButtonPressed(0, -1 * stepUp, 0)
                : onButtonPressed(0, 0, 1 * stepUp),
            locked: false,
            limited: controller.isStepUpLimited,
            stepLabel: _stepLabel(stepUp),
            showLabelOnTop: false,
          ),
          ContinuousPressButton.LaserContinuousPressButton(
            icon: UniconsLine.arrow_up_right,
            onPressed: controller.verticalLock
                ? () {}
                : () => onButtonPressed(-1 * stepUpDx, 0, 1 * stepUpDx),
            radius: BorderRadius.only(
              topRight: Radius.circular(20),
            ),
            locked: controller.verticalLock,
            limited: controller.isStepUpDxLimited,
            stepLabel: _stepLabel(stepUpDx),
            showLabelOnTop: false,
          ),
          ContinuousPressButton.LaserContinuousPressButton(
            icon: UniconsLine.arrow_left,
            onPressed: controller.verticalLock
                ? () {}
                : () => onButtonPressed(1 * stepLeft, 0, 0),
            locked: controller.verticalLock,
            limited: controller.isStepLeftLimited,
            stepLabel: _stepLabel(stepLeft),
            showLabelOnTop: false,
          ),
          // HOME / START
          ContinuousPressButton.LaserContinuousPressButton(
            // BOTTONE HOME
            icon: UniconsLine.home_alt,
            onPressed: controller.verticalLock ? () {} : onGoToHomePressed,
            locked: controller.verticalLock,
            onlyLongPress: true,
          ), // BOTTONE HOME
          // HOME / END
          ContinuousPressButton.LaserContinuousPressButton(
            icon: UniconsLine.arrow_right,
            onPressed: controller.verticalLock
                ? () {}
                : () => onButtonPressed(-1 * stepRight, 0, 0),
            locked: controller.verticalLock,
            limited: controller.isStepRightLimited,
            stepLabel: _stepLabel(stepRight),
            showLabelOnTop: false,
          ),
          ContinuousPressButton.LaserContinuousPressButton(
            icon: UniconsLine.arrow_down_left,
            onPressed: controller.verticalLock
                ? () {}
                : () => onButtonPressed(1 * stepDownSx, 0, -1 * stepDownSx),
            radius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
            ),
            locked: controller.verticalLock,
            limited: controller.isStepDownSxLimited,
            stepLabel: _stepLabel(stepDownSx),
            showLabelOnTop: true,
          ),
          ContinuousPressButton.LaserContinuousPressButton(
            icon: UniconsLine.arrow_down,
            onPressed: () => controller.isPianoRotolamento
                ? onButtonPressed(0, 1 * stepDown, 0)
                : onButtonPressed(0, 0, -1 * stepDown),
            locked: false,
            limited: controller.isStepDownLimited,
            stepLabel: _stepLabel(stepDown),
            showLabelOnTop: true,
          ),
          ContinuousPressButton.LaserContinuousPressButton(
            icon: UniconsLine.arrow_down_right,
            onPressed: controller.verticalLock
                ? () {}
                : () => onButtonPressed(-1 * stepDownDx, 0, -1 * stepDownDx),
            radius: BorderRadius.only(bottomRight: Radius.circular(20)),
            locked: controller.verticalLock,
            limited: controller.isStepDownDxLimited,
            stepLabel: _stepLabel(stepDownDx),
            showLabelOnTop: true,
          ),
        ],
      ),
    );
  }
}
