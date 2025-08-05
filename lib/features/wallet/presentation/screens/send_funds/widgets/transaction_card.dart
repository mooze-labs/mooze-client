import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

const double cardPadding = 12.0;
const double borderRadius = 12.0;

class TransactionCard extends StatelessWidget {
  final String content;

  const TransactionCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}