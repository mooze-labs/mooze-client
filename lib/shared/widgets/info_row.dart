import 'package:flutter/material.dart';
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
    Key? key,
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
    this.labelFontWeight,
    this.valueFontWeight,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor ?? Colors.white70,
            fontSize: fontSize,
            fontWeight: labelFontWeight ?? FontWeight.normal,
          ),
        ),
        SizedBox(width: 8), 
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
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
    Key? key,
    required this.label,
    this.labelColor,
    this.labelFontWeight,
    this.fontSize = 14,
    this.shimmerWidth = 80,
    this.shimmerHeight = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor ?? Colors.white70,
            fontSize: fontSize,
            fontWeight: labelFontWeight ?? FontWeight.normal,
          ),
        ),
        SizedBox(width: 8),
        Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[600]!,
          child: Container(
            width: shimmerWidth,
            height: shimmerHeight,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}