import 'package:flutter/material.dart';
import 'package:grw_laser/common_components/loading_spinner.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/components/laser_play_pause_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_rectangle_commands.dart';
import 'package:grw_laser/pages/laser_page/components/laser_taken_points_display.dart';
import 'package:grw_laser/pages/laser_page/components/laser_point_actions_dock.dart';
import 'package:grw_laser/pages/laser_page/components/laser_top_actions_bar.dart';
import 'package:grw_laser/pages/laser_page/components/laser_direction_selector.dart';
import 'package:grw_laser/pages/laser_page/components/laser_viewer_webview.dart';
import 'package:grw_laser/pages/laser_page/components/laser_joystick_dashboard.dart';
import 'package:grw_laser/pages/laser_page/components/laser_position_dashboard.dart';
import 'package:grw_laser/pages/laser_page/components/laser_robot_position_banner.dart';
import 'package:grw_laser/pages/laser_page/components/laser_welding_area.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_panel_state.dart';
import 'package:grw_laser/services/color_service.dart';

class LaserPageBody extends StatelessWidget {
  final LaserPageController controller;
  const LaserPageBody({super.key, required this.controller});

  Widget _buildWeldingProgressBar() {
    //
    //
    //
    final hasWeldingLength = controller.totalWeldingLength > 0;
    final rawProgress = hasWeldingLength
        ? controller.totalWeldedLength / controller.totalWeldingLength
        : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);
    final isActivelyWelding =
        controller.weldingStatus == LaserPageController.weldingStatusWelding;
    final progressColor = isActivelyWelding ? AppColors.sagaBlue : Colors.grey;
    final progressText =
        hasWeldingLength ? "${(progress * 100).toStringAsFixed(0)}%" : "0%";
    //
    //
    //
    return Stack(
      children: [
        LinearProgressIndicator(
          minHeight: 24,
          backgroundColor: AppColors.lightGray,
          color: progressColor,
          value: progress,
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Text(
              progressText,
              style: TextStyle(
                color: isActivelyWelding && progress > 0.49
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
    //
    //
    //
  }

  @override
  Widget build(BuildContext context) {
    //
    //
    //
    final isDockOnRight = controller.panelAlignment != 'right';
    final isWeldingStickyMode = controller.connectionStatus &&
        controller.pageState == LaserPanelState.tipoSaldatura &&
        !controller.mostraJoystick;
    //
    //
    //
    return Container(
      color: ColorService.hexToColor(controller.settings.color),
      child: Padding(
        padding:
            const EdgeInsets.only(top: 0.0, bottom: 0.0, left: 8.0, right: 8.0),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LaserTopActionsBar(controller: controller),
              Expanded(
                child: AbsorbPointer(
                  absorbing: controller.isWaitingHomeReach,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isWeldingStickyMode)
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            LaserRobotPositionBanner(controller: controller),
                            _ExpandableViewer(
                              controller: controller,
                              flexible: true,
                            ),
                            _buildWeldingProgressBar(),
                            SingleChildScrollView(
                              clipBehavior: Clip.hardEdge,
                              physics: NeverScrollableScrollPhysics(),
                              primary: true,
                              child: LaserWeldingArea(controller: controller),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 24.0, bottom: 24.0),
                              child: LaserPlayPauseButton(
                                controller: controller,
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          color: Colors.white,
                          child:
                              Column(mainAxisSize: MainAxisSize.max, children: [
                            if (controller.connectionStatus &&
                                (controller.pageState ==
                                        LaserPanelState.joystick ||
                                    controller.mostraJoystick)) ...[
                              LaserRobotPositionBanner(controller: controller),
                              Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  LaserPositionDashboard(
                                      controller: controller),
                                  LaserRectangleCommands(
                                    controller: controller,
                                    canMoveRobot: controller.canMoveRobot,
                                    stopwatch: controller.stopwatch,
                                    posizioneRobot: controller.posizioneRobot,
                                  ),
                                  if (controller.isWaitingHomeReach)
                                    Positioned.fill(
                                      child: Container(
                                        color: AppColors.sagaBlue
                                            .withValues(alpha: 0.55),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "IN ATTESA DELLA POSIZIONE HOME",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              _buildWeldingProgressBar(),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: isDockOnRight
                                        ? 0
                                        : LaserPointActionsDock.reservedWidth +
                                            4,
                                    right: isDockOnRight
                                        ? LaserPointActionsDock.reservedWidth +
                                            4
                                        : 0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      SizedBox(height: 5),
                                      LaserDirectionSelector(
                                          controller: controller),
                                      if (controller.pageState ==
                                          LaserPanelState.tipoSaldatura)
                                        _ExpandableViewer(
                                            controller: controller,
                                            flexible: false),
                                      LaserJoystickDashboard(
                                          controller: controller),
                                      if (controller.showTakenPointsPanel)
                                        Expanded(
                                          child: LaserTakenPointsDisplay(
                                            controller: controller,
                                            fillAvailableHeight: true,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ]),
                        ),
                      if (!controller.connectionStatus ||
                          controller.loadingDati)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (controller.isConnectingToRobot)
                                LoadingSpinner(
                                  color: AppColors.sagaBlue,
                                ),
                              SizedBox(
                                height: 16,
                              ),
                              Text(
                                  controller.isConnectingToRobot
                                      ? "Connessione..."
                                      : controller.connectionStatus
                                          ? "Connesso"
                                          : "Disconnesso",
                                  style: TextStyle(
                                      color: AppColors.sagaBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20))
                            ],
                          ),
                        ),
                      if (controller.connectionStatus &&
                          !controller.loadingDati &&
                          controller.pageState == LaserPanelState.joystick)
                        Positioned(
                          top: 340,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            ignoring: false,
                            child: LaserPointActionsDock(
                              controller: controller,
                              alignRight: isDockOnRight,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableViewer extends StatelessWidget {
  final LaserPageController controller;
  final bool flexible;

  const _ExpandableViewer({
    required this.controller,
    required this.flexible,
  });

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LaserViewerWebview(controller: controller, onExpand: null),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.fullscreen_exit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (flexible) {
      return Expanded(
        child: LaserViewerWebview(
          controller: controller,
          onExpand: () => _openFullscreen(context),
        ),
      );
    }
    return LaserViewerWebview(
      controller: controller,
      onExpand: () => _openFullscreen(context),
    );
  }
}
