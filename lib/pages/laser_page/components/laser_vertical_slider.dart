import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/components/laser_nuvola_params_button.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserStepSelector extends StatefulWidget {
  final LaserPageController controller;

  const LaserStepSelector({required this.controller});

  @override
  State<LaserStepSelector> createState() => _LaserStepSelectorState();
}

class _LaserStepSelectorState extends State<LaserStepSelector> {
  static const double _leftAlignedInset = 32;
  static const List<double> _steps = [
    0.5,
    1,
    2,
    3,
    5,
    10,
    20,
    30,
    50,
    75,
    100,
    200,
    300,
    500,
  ];

  String _label(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  Widget _buildStepChip(double v) {
    final selected = widget.controller.step == v;
    return GestureDetector(
      onTapDown: (_) => Vibrator.shortVibration(),
      onTap: () {
        setState(() {
          widget.controller.step = v;
        });
      },
      child: Container(
        width: 60,
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.sagaBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.sagaBlue : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Text(
          _label(v),
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _onNuvolaChanged(bool value) {
    setState(() {
      widget.controller.modalitaNuvolaNotifier.value = value;
    });
    if (value) {
      // Rimuovi tutti gli ordini esistenti
      for (final point in widget.controller.points.points) {
        point.order = null;
      }
      widget.controller.notifyPointsOrderChanged();
    } else {
      // Ripristina la direzione cordoni di default per il tipo
      widget.controller.setDirezioneCordoni(
          widget.controller.defaultDirezioneCordoniForTipo);
      // Ripristina i parametri nuvola ai valori di default
      widget.controller.nuvolaInterpMethodController.text = 'smooth';
      widget.controller.nuvolaSmoothLambdaController.text = '0.000001';
      widget.controller.nuvolaInterpKController.text = '8';
      // Azzera isBase e isLimite su tutti i punti
      for (final point in widget.controller.points.points) {
        point.isBase = false;
        point.isLimite = false;
      }
      // Ripristina la modalità selezione a 'perimetro'
      widget.controller.pointSelectionModeNotifier.value = 'perimetro';
    }
    // Ricalcola canGeneratePoints e ridisegna
    widget.controller.dashboardRedrawPoints?.call();
    widget.controller.mySetState?.call(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: _leftAlignedInset, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blocco passo robot
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Passo robot (mm)',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.start,
                spacing: 6,
                runSpacing: 6,
                children:
                    _steps.sublist(0, (_steps.length / 2).ceil()).map((v) {
                  return _buildStepChip(v);
                }).toList(),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.start,
                spacing: 6,
                runSpacing: 6,
                children:
                    _steps.sublist((_steps.length / 2).ceil()).map((v) {
                  return _buildStepChip(v);
                }).toList(),
              ),
            ],
          ),
          const SizedBox(width: 48),
          // Blocco modalità nuvola
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Modalità Nuvola',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Switch(
                value: widget.controller.modalitaNuvolaNotifier.value,
                activeThumbColor: AppColors.sagaBlue,
                activeTrackColor: AppColors.sagaBlue.withValues(alpha: 0.5),
                onChanged: _onNuvolaChanged,
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Bottone parametri nuvola (visibile solo se nuvola attiva)
          ValueListenableBuilder<bool>(
            valueListenable: widget.controller.modalitaNuvolaNotifier,
            builder: (_, isNuvola, __) {
              if (!isNuvola) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: LaserNuvolaParamsButton(controller: widget.controller),
              );
            },
          ),
        ],
      ),
    );
  }
}
