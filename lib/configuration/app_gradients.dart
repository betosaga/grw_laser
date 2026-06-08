import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';

class AppGradients {
  static const LinearGradient drawerBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.sagaBlue,
      Color(0xFF143F6B),
    ],
  );
}
