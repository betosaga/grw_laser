import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserSovrapposizioneCordone extends StatelessWidget {
  final LaserPageController controller;
  const LaserSovrapposizioneCordone({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Row(
        children: [
          Text("Sovrapposizione\ncordone (0 - 100) %\nDefault: 33.3"),
          SizedBox(
            width: 16,
          ),
          Expanded(
              child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            controller: controller.sovrapposizioneCordone,
          )),
          SizedBox(
            width: 16,
          ),
          Text("Larghezza\ncordone (mm)"),
          SizedBox(
            width: 16,
          ),
          Expanded(
              child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            controller: controller.larghezzaCordone,
          )),
        ],
      ),
    );
  }
}
