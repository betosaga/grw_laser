import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/components/laser_offset_fine.dart';
import 'package:grw_laser/pages/laser_page/components/laser_offset_inizio.dart';
import 'package:grw_laser/pages/laser_page/components/laser_offset_strato.dart';
import 'package:grw_laser/pages/laser_page/components/laser_salda_strato.dart';
import 'package:grw_laser/pages/laser_page/components/laser_scostamento_strato.dart';
import 'package:grw_laser/pages/laser_page/components/laser_velocita_saldatura.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserWeldingArea extends StatelessWidget {
  final LaserPageController controller;
  LaserWeldingArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LaserScostamentoStrato(controller: controller),
        Divider(),
        LaserOffsetInizio(controller: controller),
        Divider(),
        LaserOffsetFine(controller: controller),
        Divider(),
        Offstage(
          offstage: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LaserVelocitaSaldatura(
                controller: controller,
              ),
              Divider(),
            ],
          ),
        ),
        LaserOffsetStrato(controller: controller),
        Divider(),
        LaserSaldaStrato(
          laserPageController: controller,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Text(
              "Cordone ${controller.cordone}  |  Start cordone: ${controller.cordoneiniziale}  |  End cordone: ${controller.cordonefinale}  |  MAX num cordoni: ${controller.numerocordonitotale}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
