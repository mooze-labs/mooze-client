import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_base.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.subtitle,
          ),
          Text(
            value,
            style: AppTextStyles.value.copyWith(
              color: valueColor ?? Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}