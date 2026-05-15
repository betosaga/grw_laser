import 'package:flutter/material.dart';

class LaserPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Example drawing: a simple line
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5;

    final rectControrotaia = Rect.fromPoints(Offset(50, 50), Offset(100, 100));

    canvas.drawRect(rectControrotaia, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
