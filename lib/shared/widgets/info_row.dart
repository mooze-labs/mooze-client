import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;
  final FontWeight? labelFontWeight;
  final FontWeight? valueFontWeight;
  final double? fontSize;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
    this.labelFontWeight,
    this.valueFontWeight,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: labelColor,
            fontSize: fontSize,
            fontWeight: labelFontWeight ?? FontWeight.normal,
          ),
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: textTheme.labelLarge?.copyWith(
            color: valueColor,
            fontSize: fontSize,
            fontWeight: valueFontWeight ?? FontWeight.w500,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}

class ShimmerInfoRow extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final FontWeight? labelFontWeight;
  final double? fontSize;
  final double? shimmerWidth;
  final double? shimmerHeight;

  const ShimmerInfoRow({
    super.key,
    required this.label,
    this.labelColor,
    this.labelFontWeight,
    this.fontSize = 14,
    this.shimmerWidth = 80,
    this.shimmerHeight = 16,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final baseColor = context.colors.baseColor;
    final highlightColor = context.colors.highlightColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: labelColor ?? onSurface.withValues(alpha: 0.7),
            fontSize: fontSize,
            fontWeight: labelFontWeight ?? FontWeight.normal,
          ),
        ),
        SizedBox(width: 8),
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: shimmerWidth,
            height: shimmerHeight,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
