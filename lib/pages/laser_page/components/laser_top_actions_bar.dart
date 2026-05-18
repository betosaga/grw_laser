import 'package:flutter/material.dart';
// import 'package:grw_laser/pages/laser_page/components/laser_connection_buttons.dart';
import 'package:grw_laser/pages/laser_page/components/laser_debug_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_log_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_nuvola_params_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_remove_robot_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_settings_button.dart';
import 'package:grw_laser/pages/laser_page/components/laser_show_options_button.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_panel_state.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/color_service.dart';

class LaserTopActionsBar extends StatelessWidget {
  final LaserPageController controller;
  const LaserTopActionsBar({super.key, required this.controller});

  String get _controrotaiaLabel {
    switch (controller.controrotaiaModeValue) {
      case 'controrotaiadoppia':
        return 'Controrotaia: Doppia';
      case 'controrotaiasemplice':
        return 'Controrotaia: Semplice';
      case 'piano':
        return 'Controrotaia: Piano di rotolamento';
      default:
        return 'Controrotaia: ${controller.controrotaiaModeValue}';
    }
  }

  Future<void> _showChangeTipoControrotaiaDialog(BuildContext context) async {
    String selected = controller.controrotaiaModeValue;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cambia tipo controrotaia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attenzione: i punti presi verranno eliminati.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Controrotaia semplice'),
                value: 'controrotaiasemplice',
                groupValue: selected,
                onChanged: (v) => setDialogState(() => selected = v!),
              ),
              RadioListTile<String>(
                title: const Text('Controrotaia doppia'),
                value: 'controrotaiadoppia',
                groupValue: selected,
                onChanged: (v) => setDialogState(() => selected = v!),
              ),
              RadioListTile<String>(
                title: const Text('Piano di rotolamento'),
                value: 'piano',
                groupValue: selected,
                onChanged: (v) => setDialogState(() => selected = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ANNULLA'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('CONFERMA'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await controller.sendSetModeControrotaia(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: ColorService.hexToColor(controller.settings.color),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            LaserRemoveRobotButton(controller: controller),
            Expanded(
              child: IgnorePointer(
                ignoring: controller.isWaitingHomeReach,
                child: Row(
                  children: [
                    Text(
                      "Model: ${controller.robotModelRead}",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: controller.pageState == LaserPanelState.joystick
                          ? () => _showChangeTipoControrotaiaDialog(context)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  controller.settings.serialeRobot,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      fontSize: 20),
                                ),
                                Text(
                                  _controrotaiaLabel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            if (controller.pageState ==
                                LaserPanelState.joystick) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 22,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: controller.modalitaNuvolaNotifier,
                      builder: (_, isNuvola, __) {
                        if (!isNuvola ||
                            controller.pageState != LaserPanelState.tipoSaldatura) {
                          return const SizedBox.shrink();
                        }
                        return LaserNuvolaParamsButton(controller: controller);
                      },
                    ),
                    LaserShowOptionsButton(
                      controller: controller,
                    ),
                    LaserLogButton(controller: controller),
                    LaserSettingsButton(controller: controller),
                    LaserDebugButton(controller: controller),
                    // Bottone fulmine (connetti/disconnetti) nascosto su richiesta.
                    // Ripristino rapido: decommentare import + widget qui sotto.
                    // if (!controller.loadingDati)
                    //   LaserConnectionButtons(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
