import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/model/points_free.dart';

class LaserRectanglePainter extends CustomPainter {
  Offset position;
  PointsFree points;
  final double rectWidth;
  final double rectHeight;
  final double circleRadius;
  final Offset panOffset;
  final double viewScale;

  LaserRectanglePainter(this.position, this.points, this.rectWidth,
      this.rectHeight, this.circleRadius,
      [this.panOffset = Offset.zero, this.viewScale = 1.0]);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(255, 0, 0, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cursorPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 0.2;

    // Draw rectangle
    canvas.drawRect(Rect.fromLTWH(0, 0, rectWidth, rectHeight), paint);

    // Convert the position to local coordinates
    double localDx = position.dx * viewScale + panOffset.dx + rectWidth / 2;
    double localDy = position.dy * viewScale + panOffset.dy + rectHeight / 2;

    // Draw cross cursor
    canvas.drawLine(
        Offset(localDx, 0), Offset(localDx, rectHeight), cursorPaint);
    canvas.drawLine(
        Offset(0, localDy), Offset(rectWidth, localDy), cursorPaint);

    _drawPoints(canvas, points.points, size);
  }

  void _drawPoints(Canvas canvas, List<Point> points, Size size) {
    // Draw points
    for (var point in points) {
      if (point.dashboardPosition == null) continue;
      final pointPaint = Paint();
      // Colore sempre visibile in base allo stato del punto
      Color dotColor;
      if (point.isSelected) {
        dotColor = Colors.orange;
      } else if (point.isBase) {
        dotColor = AppColors.green;
      } else if (point.isLimite) {
        dotColor = AppColors.red;
      } else {
        dotColor = AppColors.sagaBlue;
      }
      pointPaint.color = dotColor;
      pointPaint.style = PaintingStyle.fill;

        double pointDx =
          point.dashboardPosition!.dx * viewScale + panOffset.dx + rectWidth / 2;
        double pointDy =
          point.dashboardPosition!.dy * viewScale + panOffset.dy + rectHeight / 2;
      final circleCenter = Offset(pointDx, pointDy);
      canvas.drawCircle(
          circleCenter, circleRadius, pointPaint); // Draw circle with radius

      if (point.order != null) {
        final orderText = "${point.order!}";

        final strokePainter = TextPainter(
          text: TextSpan(
            text: orderText,
            style: TextStyle(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.black.withValues(alpha: 0.55),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

        final fillPainter = TextPainter(
          text: const TextSpan(
            text: "",
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        fillPainter.text = TextSpan(
          text: orderText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        );
        fillPainter.layout();

        final textOffset = Offset(
          circleCenter.dx - fillPainter.width / 2,
          circleCenter.dy - fillPainter.height / 2,
        );

        strokePainter.paint(canvas, textOffset);
        fillPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  // Metodo per pulire tutto
  void clear() {}

  void clearCanvas(Canvas canvas) {
    canvas.restore();
  }
}
