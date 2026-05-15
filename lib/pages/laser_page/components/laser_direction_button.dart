import 'package:flutter/material.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserDirectionButton extends StatelessWidget {
  final String direction;
  final VoidCallback onPressed;

  LaserDirectionButton({required this.direction, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => Vibrator.shortVibration(),
      child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(0),
        shape: CircleBorder(),
        backgroundColor: Colors.blue,
      ),
      child: Text(
        direction,
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
    );
  }
}
