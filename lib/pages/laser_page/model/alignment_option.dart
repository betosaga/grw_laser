import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';

class AlignmentOption extends StatelessWidget {
  //
  //
  //
  final String value;
  final String selected;
  final String label;
  final String description;
  final IconData icon;
  final void Function(String) onTap;
  //
  //
  //
  const AlignmentOption({
    super.key,
    required this.value,
    required this.selected,
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });
  //
  //
  //
  @override
  Widget build(BuildContext context) {
    //
    //
    //
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sagaBlue.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.sagaBlue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.sagaBlue : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.sagaBlue : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.sagaBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  //
  //
  //
}
