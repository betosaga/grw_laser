import 'package:flutter/material.dart';
import 'package:flutter_responsive_framework/flutter_responsive_framework.dart';
import 'package:grw_laser/pages/laser_page/components/laser_j4_j5_joystick.dart';
import 'package:grw_laser/pages/laser_page/components/laser_j6_joystick.dart';
// import 'package:grw_laser/pages/laser_page/components/laser_jog.dart';
import 'package:grw_laser/pages/laser_page/components/laser_joystick.dart';
import 'package:grw_laser/pages/laser_page/components/laser_joystick_x.dart';
import 'package:grw_laser/pages/laser_page/components/laser_vertical_slider.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserJoystickDashboard extends StatelessWidget {
  final LaserPageController controller;

  const LaserJoystickDashboard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final mirrored = controller.panelAlignment == 'right';

    final joystickWidget = Container(
      width: 34.w,
      child: LaserJoystick(controller: controller),
    );

    final jogWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LaserJ4J5Joystick(controller: controller),
        // SizedBox(height: 8),
        // LaserJog(controller: controller, maxstepx: controller.effectiveJogMaxStep),
      ],
    );

    final centerWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LaserJ6Joystick(controller: controller),
        Container(
          padding: EdgeInsets.all(0),
          width: 13.w,
          child: LaserJoystickX(controller: controller),
        ),
      ],
    );

    return SizedBox(
      height: 36.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selettore passo chip
          SizedBox(
            width: double.infinity,
            child: LaserStepSelector(controller: controller),
          ),
          const SizedBox(height: 10),
          // Controlli joystick
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: mirrored
                  ? [
                      jogWidget,
                      SizedBox(width: 56),
                      centerWidget,
                      SizedBox(width: 56),
                      joystickWidget,
                    ]
                  : [
                      joystickWidget,
                      SizedBox(width: 56),
                      centerWidget,
                      SizedBox(width: 56),
                      jogWidget,
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
