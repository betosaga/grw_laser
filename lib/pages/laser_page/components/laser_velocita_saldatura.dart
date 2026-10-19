import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/components/laser_numeric_pad_input.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserVelocitaSaldatura extends StatelessWidget {
  final LaserPageController controller;

  const LaserVelocitaSaldatura({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Velocità saldatura',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int p = 0; p < controller.larghezzasaldatura.length; p++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: LaserNumericPadInput(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: AppColors.sagaBlue,
                          width: 2.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      border: const OutlineInputBorder(),
                      labelText: 'V${p + 1}',
                    ),
                    controller: controller.velocitaSaldaturaController[p],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
