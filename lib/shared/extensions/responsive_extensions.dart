import 'package:flutter/material.dart';

extension ResponsiveText on BuildContext {
  double responsiveFont(double baseSize) {
    final width = MediaQuery.of(this).size.width;
    if (width <= 375) return baseSize * 0.85;
    if (width <= 400) return baseSize * 0.95;
    return baseSize;
  }
}
