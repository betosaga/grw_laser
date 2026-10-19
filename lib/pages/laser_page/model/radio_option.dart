import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';

class RadioOption extends StatelessWidget {
  //
  //
  //
  final String label;
  final bool selected;
  final VoidCallback onTap;
  //
  //
  //
  const RadioOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  //
  //
  //
  @override
  Widget build(BuildContext context) {
    const blue = AppColors.sagaBlue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? blue.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? blue : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? blue : Colors.grey[500],
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? blue : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
