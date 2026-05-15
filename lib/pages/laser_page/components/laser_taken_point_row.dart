import 'package:flutter/material.dart';
import 'package:grw_laser/model/point.dart';

class LaserTakenPointRow extends StatelessWidget {
  final String title;
  final Point point;
  const LaserTakenPointRow({required this.title, required this.point});

  @override
  Widget build(BuildContext context) {
    return RichText(
        text: TextSpan(
            text: "$title  X: ",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 8),
            children: [
          TextSpan(
              text: "${point.x}",
              style: TextStyle(
                color: Colors.blue,
              )),
          TextSpan(text: " Y: ", style: TextStyle(color: Colors.black)),
          TextSpan(text: "${point.y}", style: TextStyle(color: Colors.green)),
          TextSpan(text: " Z: ", style: TextStyle(color: Colors.black)),
          TextSpan(text: "${point.z}", style: TextStyle(color: Colors.red)),
          TextSpan(text: " J1: ", style: TextStyle(color: Colors.black)),
          TextSpan(text: "${point.j1}", style: TextStyle(color: Colors.blue)),
          TextSpan(text: " J2: ", style: TextStyle(color: Colors.black)),
          TextSpan(text: "${point.j2}", style: TextStyle(color: Colors.green)),
          TextSpan(text: " J3: ", style: TextStyle(color: Colors.black)),
          TextSpan(text: "${point.j3}", style: TextStyle(color: Colors.red)),
        ]));
  }
}
