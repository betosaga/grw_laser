import 'dart:ui';

extension ColorWithAlphaDouble on Color {
  Color withAlphaDouble({required double alpha}) {
    return this.withAlpha(alpha.toInt());
  }

  Color withAlphaFromOpacity({required double alpha}) {
    return this.withAlpha((alpha * 255).toInt());
  }
}
