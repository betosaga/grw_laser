import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';
import 'package:unicons/unicons.dart';

class LaserPointActionsDock extends StatefulWidget {
  static const double reservedWidth = 84;

  final LaserPageController controller;
  final bool alignRight;

  const LaserPointActionsDock({super.key, 
    required this.controller,
    required this.alignRight,
  });

  @override
  State<LaserPointActionsDock> createState() => _LaserPointActionsDockState();
}

class _LaserPointActionsDockState extends State<LaserPointActionsDock> {
  static const double _dockWidth = 84;
  static const double _handleWidth = 24;
  static const double _corner = 16;
  static const bool _allowCollapse = false;
  static const Color _safeMissingColor = Color(0xFFA01919);
  static const Color _safeSetColor = Color(0xFF4F81CE);

  double _hiddenProgress = 0; // 0 = aperta, 1 = nascosta (solo maniglia)

  double get _maxHideOffset => _dockWidth - _handleWidth;

  void _setProgressFromDrag(DragUpdateDetails details) {
    final direction = widget.alignRight ? 1.0 : -1.0;
    final delta = details.delta.dx * direction;
    final next = (_hiddenProgress + delta / _maxHideOffset).clamp(0.0, 1.0);
    setState(() {
      _hiddenProgress = next;
    });
  }

  void _settleAfterDrag() {
    setState(() {
      _hiddenProgress = _hiddenProgress > 0.45 ? 1.0 : 0.0;
    });
  }

  void _toggleHandle() {
    setState(() {
      _hiddenProgress = _hiddenProgress >= 0.95 ? 0.0 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHidden = _allowCollapse && _hiddenProgress >= 0.95;
    final direction = widget.alignRight ? 1.0 : -1.0;
    final translateX =
        _allowCollapse ? direction * _maxHideOffset * _hiddenProgress : 0.0;

    final handle = GestureDetector(
      onTap: _toggleHandle,
      child: Container(
        width: _handleWidth,
        height: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_corner),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Icon(
          widget.alignRight ? Icons.chevron_left : Icons.chevron_right,
          color: AppColors.sagaBlue,
          size: 22,
        ),
      ),
    );

    final dock = Container(
      width: _dockWidth,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_corner),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: widget.controller.canTakePointNotifier,
            builder: (_, canTakePoint, __) {
              return _DockButton(
                icon: UniconsLine.focus_add,
                enabled: canTakePoint,
                backgroundColor:
                    canTakePoint ? AppColors.sagaBlue : AppColors.lightGray,
                onPressed: canTakePoint
                    ? () => widget.controller.addCurrentPoint(context: context)
                    : null,
              );
            },
          ),
          const SizedBox(height: 12),
          _DockButton(
            icon: Icons.undo_rounded,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Conferma'),
                      content:
                          const Text('Annullare l\'ultimo punto acquisito?'),
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
                  ) ??
                  false;
              if (!confirmed) return;
              widget.controller.undoLastPoint(context: context);
            },
          ),
          const SizedBox(height: 12),
          _DockButton(
            icon: UniconsLine.trash,
            onPressed: () =>
                widget.controller.deleteAllPoints(context: context),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: Listenable.merge([
              widget.controller.safePositionNotifier,
              widget.controller.robotSafePositionFlagNotifier,
            ]),
            builder: (_, __) {
              final hasSafePosition = widget.controller.effectiveHasSafePosition;
              return _DockButton(
                icon: Icons.safety_check,
                backgroundColor:
                    hasSafePosition ? _safeSetColor : _safeMissingColor,
                onPressed: () async {
                  debugPrint(
                    '[SAFE_POSITION][UI] Apertura dialog opzioni safe position',
                  );
                  String? selected;
                  await showDialog<void>(
                    context: context,
                    builder: (ctx) => StatefulBuilder(
                      builder: (ctx, setDialogState) => AlertDialog(
                        title: const Text('Safe Position'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: const Text('Vai'),
                              subtitle: const Text(
                                  'Muovi il robot alla safe position'),
                              value: 'vai',
                              groupValue: selected,
                              onChanged: hasSafePosition
                                  ? (v) =>
                                      setDialogState(() => selected = v)
                                  : null,
                            ),
                            RadioListTile<String>(
                                title: const Text('Imposta'),
                              subtitle: const Text(
                                  'Imposta la posizione attuale come safe'),
                              value: 'setta',
                              groupValue: selected,
                              onChanged: (v) =>
                                  setDialogState(() => selected = v),
                            ),
                            RadioListTile<String>(
                              title: const Text('Elimina'),
                              subtitle: const Text(
                                  'Rimuovi la safe position registrata'),
                              value: 'elimina',
                              groupValue: selected,
                              onChanged: hasSafePosition
                                  ? (v) =>
                                      setDialogState(() => selected = v)
                                  : null,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('ANNULLA'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                            onPressed: selected == null
                                ? null
                                : () => Navigator.of(ctx).pop(),
                            child: const Text('CONFERMA'),
                          ),
                        ],
                      ),
                    ),
                  );
                  debugPrint(
                    '[SAFE_POSITION][UI] Dialog chiuso, selezione=$selected',
                  );
                  if (selected == null) {
                    debugPrint(
                      '[SAFE_POSITION][UI] Nessuna opzione selezionata, esco',
                    );
                    return;
                  }
                  switch (selected) {
                    case 'vai':
                      debugPrint(
                        '[SAFE_POSITION][UI] Azione richiesta: VAI -> sendGoToSafePosition()',
                      );
                      await widget.controller.sendGoToSafePosition();
                      debugPrint(
                        '[SAFE_POSITION][UI] Azione VAI completata',
                      );
                      break;
                    case 'setta':
                      debugPrint(
                        '[SET_SAFE_POSITION][UI] Azione richiesta: IMPOSTA -> sendSetSafePosition(askConfirmation: false)',
                      );
                      await widget.controller
                          .sendSetSafePosition(askConfirmation: false);
                      debugPrint(
                        '[SET_SAFE_POSITION][UI] Azione IMPOSTA completata',
                      );
                      break;
                    case 'elimina':
                      widget.controller.deleteSafePosition();
                      break;
                  }
                },
              );
            },
          ),
          const SizedBox(height: 12),
          _DockButton(
            icon: UniconsLine.save,
            backgroundColor: AppColors.yellow,
            onPressed: () => widget.controller.salvaPointsToHistory(),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: widget.controller.canGeneratePointsNotifier,
            builder: (_, canGeneratePoints, __) {
              final enabled = canGeneratePoints &&
                  !widget.controller.sendingSimulationPoints;
              return _DockButton(
                icon: Icons.auto_awesome,
                backgroundColor:
                    enabled ? AppColors.green : AppColors.lightGray,
                enabled: enabled,
                onPressed: enabled
                    ? () async {
                        final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Conferma'),
                                content:
                                    const Text('Avviare la generazione punti?'),
                                actions: [
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('ANNULLA'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('CONFERMA'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (!confirmed) return;
                        widget.controller.sendPointsToFastAPI();
                      }
                    : null,
              );
            },
          ),
        ],
      ),
    );

    return Align(
      alignment:
          widget.alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: !_allowCollapse
            ? dock
            : isHidden
                ? handle
                : GestureDetector(
                    onHorizontalDragUpdate: _setProgressFromDrag,
                    onHorizontalDragEnd: (_) => _settleAfterDrag(),
                    child: Transform.translate(
                      offset: Offset(translateX, 0),
                      child: dock,
                    ),
                  ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final bool enabled;

  const _DockButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor = AppColors.sagaBlue,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: (enabled && onPressed != null)
            ? (_) => Vibrator.shortVibration()
            : null,
        onTap: (!enabled || onPressed == null)
            ? null
            : () {
                onPressed?.call();
              },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
