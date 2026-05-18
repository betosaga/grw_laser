import 'package:flutter/material.dart';

class LaserRobotCompactField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final double? fieldWidth;

  const LaserRobotCompactField({super.key, 
    required this.title,
    required this.controller,
    this.fieldWidth,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextFormField(
          textAlign: TextAlign.center,
          controller: controller,
        ),
      ],
    );

    if (fieldWidth == null) return content;
    return SizedBox(width: fieldWidth, child: content);
  }
}
