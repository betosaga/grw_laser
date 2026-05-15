import 'package:flutter/material.dart';
import 'package:grw_laser/common_components/loading_spinner.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/components/laser_choose_robot_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_close_page_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_page_title.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LaserPageHub extends StatefulWidget {
  LaserPageHub({super.key});

  @override
  State<LaserPageHub> createState() => _LaserPageHubState();
}

class _LaserPageHubState extends State<LaserPageHub> {
  final controller = LaserPageHubController();

  @override
  void initState() {
    controller.mySetState = mySetState;
    controller.onInit();
    WakelockPlus.enable();
    super.initState();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.context = context;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: AppColors.sagaBlue,
          title: LaserPageTitle(
            controller: controller,
          ),
          leading: LaserClosePageButton(
            controller: controller,
          ),
          actions: [
            LaserChooseRobotButton(controller: controller),
          ],
        ),
        body: controller.isThinking
            ? Center(
                child: LoadingSpinner(color: AppColors.sagaBlue),
              )
            : controller.laserPages.length > 0
                ? PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onLaserPageChanged,
                    itemCount: controller.laserPages.length,
                    itemBuilder: (context, index) {
                      return controller.laserPages[index];
                    })
                : Center(
                    child: Text(
                      "NESSUN ROBOT COLLEGATO",
                      style: TextStyle(fontSize: 24),
                    ),
                  ));
  }

  void mySetState(VoidCallback? f) {
    if (f == null) return;
    if (mounted) {
      setState(f);
    }
  }
}
