import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/services/color_service.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';

class SelectLaserRobotSettingsDialog extends StatefulWidget {
  final List<LaserRobotSettings> list;

  const SelectLaserRobotSettingsDialog({super.key, required this.list});

  @override
  State<SelectLaserRobotSettingsDialog> createState() =>
      _SelectLaserRobotSettingsDialogState();
}

class _SelectLaserRobotSettingsDialogState
    extends State<SelectLaserRobotSettingsDialog> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      constraints: const BoxConstraints(maxWidth: 448, maxHeight: 920),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sagaBlue.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.precision_manufacturing_outlined,
                  color: AppColors.sagaBlue,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Text(
                  '${list.length} robot',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Selezione robot',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: list.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Nessun robot disponibile.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            : Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 6,
                radius: const Radius.circular(8),
                child: ListView.separated(
                  controller: _scrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) =>
                      _RobotSelectionCard(robot: list[index]),
                ),
              ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.sagaBlue,
            minimumSize: const Size(88, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Vibrator.shortVibration();
            Pager.pop(context, null);
          },
          child: const Text(
            'Annulla',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _RobotSelectionCard extends StatelessWidget {
  final LaserRobotSettings robot;

  const _RobotSelectionCard({required this.robot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final robotColor = ColorService.hexToColor(robot.color);
    final iconColor =
        ThemeData.estimateBrightnessForColor(robotColor) == Brightness.dark
        ? Colors.white
        : const Color(0xFF17212F);
    final borderRadius = BorderRadius.circular(18);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(
                robotColor.withValues(alpha: 0.08),
                colors.surface,
              ),
              colors.surface,
            ],
          ),
        ),
        child: InkWell(
          onTap: () {
            Vibrator.shortVibration();
            Pager.pop(context, robot);
          },
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: robotColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.precision_manufacturing_outlined,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROBOT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        robot.serialeRobot,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
