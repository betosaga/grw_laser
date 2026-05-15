import 'dart:ui';
import 'package:grw_laser/configuration/app_colors.dart';

extension FromHexString on Color {
  static Color hexToColor(String hexString, {String alphaChannel = 'FF'}) {
    try {
      final color =
          Color(int.parse(hexString.replaceFirst('#', '0x$alphaChannel')));
      return color;
    } catch (e) {
      return AppColors.sagaBlue;
    }
  }
}
