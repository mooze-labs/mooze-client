import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/new_ui_wallet/home/widgets/simple_chart_painter.dart';

class AssetCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final String percentage;
  final bool isPositive;

  const AssetCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.percentage,
    required this.isPositive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Image.asset(icon, width: 40, height: 40),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  percentage,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 16,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          // Gráfico simples simulado SEM padding
          SizedBox(
            height: 40,
            child: CustomPaint(
              painter: SimpleChartPainter(isPositive: isPositive),
              size: Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }
}
