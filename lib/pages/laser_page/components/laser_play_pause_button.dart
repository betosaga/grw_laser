import 'package:flutter/material.dart';
import 'package:grw_laser/common_components/loading_spinner.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserPlayPauseButton extends StatelessWidget {
  final LaserPageController controller;
  const LaserPlayPauseButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final playPauseWidth = MediaQuery.of(context).size.width / 3;
    final isPaused = controller.paused;
    final showStopButton = isPaused;
    final isEndOrInactive =
      controller.weldingStatus == LaserPageController.weldingStatusEnd ||
        controller.weldingStatus ==
          LaserPageController.weldingStatusInactive;
    final isPausing =
        controller.weldingStatus == LaserPageController.weldingStatusPausing;
    final canTogglePlayPause =
        controller.canPauseWelding || controller.canResumeWelding;
    final isTransitioning = controller.isPausingResuming || isPausing;

    final playPauseColor =
        isPaused ? AppColors.green : AppColors.yellow;
    final playPauseDisabled =
      isEndOrInactive || isTransitioning || !canTogglePlayPause;
    final isWaitingForStart =
      playPauseDisabled &&
      !controller.startedWeldingOnce &&
      !controller.stratoCominciato;
    final stopDisabled = controller.isStopping || !controller.canStopWelding;

    return Center(
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Play / Pausa ────────────────────────────────────────
            SizedBox(
              width: playPauseWidth,
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      playPauseDisabled ? Colors.grey[400] : playPauseColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  disabledForegroundColor: Colors.white70,
                  elevation: playPauseDisabled ? 0 : 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: playPauseDisabled ? null : () {},
                onLongPress: playPauseDisabled
                    ? null
                    : () {
                        Vibrator.mediumVibration();
                        if (isPaused) {
                          controller.resumePressed(context: context);
                        } else {
                          controller.pausePressed(context: context);
                        }
                      },
                child: isTransitioning
                    ? const LoadingSpinner(color: Colors.white)
                    : Icon(
                    isWaitingForStart
                      ? Icons.hourglass_top
                      : (isPaused ? Icons.play_arrow : Icons.pause),
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
            if (showStopButton) ...[
              const SizedBox(width: 10),
              // ── Stop ────────────────────────────────────────────────
              SizedBox(
                width: 64,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor:
                        stopDisabled ? Colors.grey[400] : AppColors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    disabledForegroundColor: Colors.white70,
                    elevation: stopDisabled ? 0 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: stopDisabled ? null : () {},
                  onLongPress: stopDisabled
                      ? null
                      : () {
                          Vibrator.longVibration();
                          controller.stopCurrentCordone(context: context);
                        },
                  child: controller.isStopping
                      ? const LoadingSpinner(color: Colors.white)
                      : const Icon(Icons.stop, size: 28),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
