import 'package:flutter/material.dart';

class LaserRobotSettingRow extends StatelessWidget {
  final String title;
  final double elementsSpacing;
  final TextEditingController controller;
  const LaserRobotSettingRow(
      {required this.title,
      required this.elementsSpacing,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
              width: 100,
              child: Text(
                title,
                textAlign: TextAlign.end,
                style: TextStyle(fontWeight: FontWeight.bold),
              )),
          SizedBox(
            width: elementsSpacing,
          ),
          Expanded(
              child: TextFormField(
            textAlign: TextAlign.center,
            controller: controller,
          ))
        ],
      ),
    );
  }
}
