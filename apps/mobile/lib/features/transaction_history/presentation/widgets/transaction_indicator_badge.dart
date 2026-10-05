import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class TransactionIndicatorBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const TransactionIndicatorBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 80,
  });

  factory TransactionIndicatorBadge.direction({
    Key? key,
    required BuildContext context,
    required bool isReceive,
    double size = 80,
  }) {
    final colors = context.colors;
    return TransactionIndicatorBadge(
      key: key,
      icon: isReceive ? Icons.south_rounded : Icons.north_rounded,
      color: isReceive ? colors.positiveColor : colors.negativeColor,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill =
        isDark
            ? HSLColor.fromColor(
              color,
            ).withLightness(0.18).withSaturation(0.45).toColor()
            : Color.lerp(color, Colors.white, 0.85)!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.475, color: color),
    );
  }
}
