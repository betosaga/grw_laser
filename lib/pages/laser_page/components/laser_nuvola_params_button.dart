import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserNuvolaParamsButton extends StatelessWidget {
  final LaserPageController controller;

  const LaserNuvolaParamsButton({super.key, required this.controller});

  Future<void> _showDialog(BuildContext context) async {
    // Lavoriamo su copie temporanee per poter annullare
    final methodCtrl = TextEditingController(
        text: controller.nuvolaInterpMethodController.text);
    final lambdaCtrl = TextEditingController(
        text: controller.nuvolaSmoothLambdaController.text);
    final kCtrl =
        TextEditingController(text: controller.nuvolaInterpKController.text);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Parametri Nuvola'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'interp_method',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: methodCtrl,
                decoration: const InputDecoration(
                  hintText: 'smooth',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'smooth_lambda',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: lambdaCtrl,
                decoration: const InputDecoration(
                  hintText: '0.000001',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 14),
              const Text(
                'interp_k',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: kCtrl,
                decoration: const InputDecoration(
                  hintText: '8',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
            onPressed: () {
              controller.nuvolaInterpMethodController.text =
                  methodCtrl.text.trim().isEmpty
                      ? 'smooth'
                      : methodCtrl.text.trim();
              controller.nuvolaSmoothLambdaController.text =
                  lambdaCtrl.text.trim().isEmpty
                      ? '0.000001'
                      : lambdaCtrl.text.trim();
              controller.nuvolaInterpKController.text =
                  kCtrl.text.trim().isEmpty ? '8' : kCtrl.text.trim();
              Navigator.of(ctx).pop();
            },
            child: const Text('SALVA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 36,
        icon: const Icon(Icons.settings),
        color: AppColors.sagaBlue,
        tooltip: 'Parametri Nuvola',
        onPressed: () => _showDialog(context),
      ),
    );
  }
}
