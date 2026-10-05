import 'dart:ui';

class AssetPageData {
  final String id;
  final String name;
  final String symbol;
  final String amount;
  final String value;
  final String percentage;
  final bool isPositive;
  final Color iconColor;
  final String iconText;

  AssetPageData({
    required this.id,
    required this.name,
    required this.symbol,
    required this.amount,
    required this.value,
    required this.percentage,
    required this.isPositive,
    required this.iconColor,
    required this.iconText,
  });
}
