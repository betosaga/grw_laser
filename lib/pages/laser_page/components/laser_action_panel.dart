import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';
import 'package:unicons/unicons.dart';

class LaserActionPanel extends StatefulWidget {
  final LaserPageController controller;

  const LaserActionPanel({required this.controller});

  @override
  State<LaserActionPanel> createState() => _LaserActionPanelState();
}

class _LaserActionPanelState extends State<LaserActionPanel> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8.0),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Conferma'),
                          content: const Text('Eliminare tutti i punti?'),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('ANNULLA'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('ELIMINA'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (!confirmed) return;
                  Vibrator.longVibration();
                  widget.controller.deleteAllPoints(context: context);
                },
                child: Icon(
                  UniconsLine.trash,
                  size: 44,
                  color: const Color(0xFF8B0000),
                )),
            SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: widget.controller.canTakePointNotifier,
              builder: (_, canTakePoint, __) {
                return Listener(
                  onPointerDown:
                      canTakePoint ? (_) => Vibrator.shortVibration() : null,
                  child: TextButton(
                    onPressed: canTakePoint
                        ? () =>
                            widget.controller.addCurrentPoint(context: context)
                        : null,
                    child: Icon(
                      UniconsLine.focus_add,
                      size: 44,
                      color: canTakePoint
                          ? AppColors.sagaBlue
                          : AppColors.lightGray,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void mySetState(VoidCallback? f) {
    if (f == null) return;
    if (mounted) {
      setState(f);
    }
  }
}
