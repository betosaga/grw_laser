import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/components/laser_numeric_pad_input.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserScostamentoStrato extends StatelessWidget {
  //
  //
  //
  final LaserPageController controller;
  const LaserScostamentoStrato({super.key, required this.controller});

  Widget _buildField({
    required String title,
    required TextEditingController textController,
  }) {
    //
    //
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 42,
          child: Align(
            alignment: Alignment.topCenter,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 6),
        LaserNumericPadInput(
          textAlign: TextAlign.center,
          controller: textController,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildField(
              title: "Sovrapposizione %",
              textController: controller.sovrapposizioneCordone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              title: "Larghezza cordone (mm)",
              textController: controller.larghezzaCordone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              title: controller.scostamentoStratoXLabel,
              textController: controller.scostamentoStratoXFieldController,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              title: controller.scostamentoStratoZLabel,
              textController: controller.scostamentoStratoZFieldController,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              title: "end cordone ⏱ laseroff",
              textController: controller.waitFineCordoneController,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              title: "laseroff ⏱ distacco",
              textController: controller.waitPreUscitaController,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              title: "laseron ⏱ startcordone",
              textController: controller.waitLaseronStartCordoneController,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              title: "Min length cordoni",
              textController: controller.minLengthCordoniController,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              title: "Velocità\nAvvicinamento",
              textController: controller.velocitaAvvicinamentoController,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              title: "Velocità\nAllontanamento",
              textController: controller.velocitaAllontanamentoController,
            ),
          ),
        ],
      ),
    );
  }
}
