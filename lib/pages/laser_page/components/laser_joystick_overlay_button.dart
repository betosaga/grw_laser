import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/components/laser_joystick_dashboard.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserJoystickOverlayButton extends StatefulWidget {
  final LaserPageController controller;

  const LaserJoystickOverlayButton({super.key, required this.controller});

  @override
  State<LaserJoystickOverlayButton> createState() =>
      _LaserJoystickOverlayButtonState();
}

class _LaserJoystickOverlayButtonState
    extends State<LaserJoystickOverlayButton> {
  final _overlay = OverlayPortalController();

  void _close() => setState(_overlay.hide);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_overlay.isShowing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _overlay.isShowing) _close();
      },
      child: OverlayPortal(
        overlayLocation: OverlayChildLocation.rootOverlay,
        controller: _overlay,
        overlayChildBuilder: (context) => Positioned.fill(
          child: Stack(
            children: [
              const ModalBarrier(dismissible: false, color: Colors.black54),
              SafeArea(
                child: Dialog(
                  insetPadding: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Joystick · ${widget.controller.settings.serialeRobot}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _close,
                              icon: const Icon(Icons.close),
                              label: const Text('Chiudi'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: SingleChildScrollView(
                            child: LaserJoystickDashboard(
                              controller: widget.controller,
                              fitContent: true,
                              onStepChanged: () => setState(() {}),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sagaBlue.withValues(alpha: 0.82),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: const StadiumBorder(),
          ),
          onPressed: () {
            widget.controller.unfocusScreen();
            setState(_overlay.show);
          },
          icon: const Icon(Icons.gamepad_outlined, size: 18),
          label: const Text('Joystick'),
        ),
      ),
    );
  }
}
