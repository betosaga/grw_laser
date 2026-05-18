import 'package:flutter/material.dart';
import 'package:flutter_responsive_framework/flutter_responsive_framework.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserPageTitle extends StatelessWidget {
  final LaserPageHubController controller;
  const LaserPageTitle({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Listener(
          onPointerDown: (_) => Vibrator.shortVibration(),
          child: IconButton(
              onPressed: controller.goToPreviousPage,
              icon: Icon(
                Icons.arrow_back_ios_new_sharp,
                color: Colors.white,
              )),
        ),
        Padding(
            padding: EdgeInsets.only(left: 15.px),
            child: Text(
              "LASER (${ controller.laserPages.length })",
              style: TextStyle(
                  fontSize: FontSizeHelper.NORMAL_TEXT_LARGE,
                  fontFamily: "OpenSans-Regular",
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            )),
        SizedBox(width: 20,),
            IconButton(
                onPressed: () {
                  Vibrator.shortVibration();
                  controller.goToNextRightPage();
                },
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                )),
      ],
    );
  }
}
