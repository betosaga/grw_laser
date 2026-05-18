import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserDirectionSelector extends StatelessWidget {
  final LaserPageController controller;

  const LaserDirectionSelector({super.key, required this.controller});

  Widget _buildRobotDirectionImage() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          alignment: AlignmentDirectional.center,
          children: [
            if (controller.armPosition != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                child: SizedBox(
                  height: 100,
                  child: Image.asset(
                    "images/laser/controrotaia_${controller.armPosition! ? "dx" : "sx"}_d_start.png",
                    height: 100,
                  ),
                ),
              ),
            if (controller.armPosition == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                child: SizedBox(
                  height: 100,
                  child: Image.asset(
                    "images/laser/controrotaia_dstart.png",
                    height: 100,
                  ),
                ),
              ),
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        child: Container(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: Colors.transparent,
                        onTapDown: (_) => Vibrator.shortVibration(),
                        onTap: () {
                          controller.laserDirectionSelected(selection: false);
                        },
                      ),
                    )),
                    Expanded(
                        child: Container(
                            color: Colors.transparent,
                            child: InkWell(
                              splashColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              highlightColor: Colors.transparent,
                              onTapDown: (_) => Vibrator.shortVibration(),
                              onTap: () {
                                controller.laserDirectionSelected(
                                    selection: true);
                              },
                            )))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isControrotaiaDoppia =
        controller.controrotaiaModeValue == 'controrotaiadoppia';
    const disabledLabelColor = Colors.grey;
    const disabledCheckboxFillColor = Color(0xFFBDBDBD);
    const disabledCheckboxBorderColor = Color(0xFF9E9E9E);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isControrotaiaDoppia)
            ValueListenableBuilder<int>(
              valueListenable: controller.pointsOrderVersion,
              builder: (_, __, ___) {
                return Center(
                  child: ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        opacity: 1,
                        child: _buildRobotDirectionImage(),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (Constants.LASER_DEBUG)
            ValueListenableBuilder<String?>(
              valueListenable: controller.lastInterpolaResponseNotifier,
              builder: (_, lastResponse, __) {
                if (lastResponse == null || lastResponse.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Listener(
                  onPointerDown: (_) => Vibrator.shortVibration(),
                  child: IconButton(
                    tooltip: "Apri ultimo JSON /interpola",
                    icon: const Icon(Icons.bug_report),
                    onPressed: controller.openLastInterpolaResponseDebug,
                  ),
                );
              },
            ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: controller.modalitaNuvolaNotifier,
                        builder: (_, isNuvola, __) {
                          final labelColor = isNuvola ? Colors.black : disabledLabelColor;
                          final checkboxFillColor = isNuvola ? AppColors.sagaBlue : disabledCheckboxFillColor;
                          final checkboxBorderColor = isNuvola ? Colors.transparent : disabledCheckboxBorderColor;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Modalità saldatura",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: labelColor,
                                    ),
                                  ),
                                ],
                              ),
                              ValueListenableBuilder<String>(
                                valueListenable: controller.direzioneCordoniNotifier,
                                builder: (_, direction, __) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Transform.scale(
                                            scale: 1.33,
                                            child: Listener(
                                              onPointerDown: isNuvola ? (_) => Vibrator.shortVibration() : null,
                                              child: Checkbox(
                                                value: direction == 'h',
                                                fillColor: WidgetStatePropertyAll(checkboxFillColor),
                                                side: WidgetStateBorderSide.resolveWith(
                                                  (_) => BorderSide(color: checkboxBorderColor),
                                                ),
                                                onChanged: isNuvola ? (_) => controller.setDirezioneCordoni('h') : null,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "Orizzontale",
                                            style: TextStyle(color: labelColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 22),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Transform.scale(
                                            scale: 1.33,
                                            child: Listener(
                                              onPointerDown: isNuvola ? (_) => Vibrator.shortVibration() : null,
                                              child: Checkbox(
                                                value: direction == 'v',
                                                fillColor: WidgetStatePropertyAll(checkboxFillColor),
                                                side: WidgetStateBorderSide.resolveWith(
                                                  (_) => BorderSide(color: checkboxBorderColor),
                                                ),
                                                onChanged: isNuvola ? (_) => controller.setDirezioneCordoni('v') : null,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "Verticale",
                                            style: TextStyle(color: labelColor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: controller.modalitaNuvolaNotifier,
                    builder: (_, isNuvola, __) {
                      if (!isNuvola) return const SizedBox.shrink();
                      return ValueListenableBuilder<String>(
                        valueListenable: controller.pointSelectionModeNotifier,
                        builder: (_, mode, __) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Selezione punti",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildModeChip(
                                    label: 'Base',
                                    color: AppColors.green,
                                    selected: mode == 'base',
                                    onTap: () =>
                                        controller.setPointSelectionMode('base'),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildModeChip(
                                    label: 'Limite',
                                    color: AppColors.red,
                                    selected: mode == 'limite',
                                    onTap: () => controller
                                        .setPointSelectionMode('limite'),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildModeChip(
                                    label: 'Perimetro',
                                    color: AppColors.sagaBlue,
                                    selected: mode == 'perimetro',
                                    onTap: () => controller
                                        .setPointSelectionMode('perimetro'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Vibrator.shortVibration();
        onTap();
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey.shade400,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
