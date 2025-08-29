import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AssetTransactionItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String value;
  final String time;

  const AssetTransactionItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(icon, width: 50, height: 50),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: time.contains('-') ? Colors.red : Colors.green,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
