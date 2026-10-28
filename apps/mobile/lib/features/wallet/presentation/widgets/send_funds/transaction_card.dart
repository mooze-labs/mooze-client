import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

const double cardPadding = 12.0;
const double borderRadius = 12.0;

/// A line of transaction text on a glass panel.
class TransactionCard extends StatelessWidget {
  final String content;

  const TransactionCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: GlassPanel(
          padding: const EdgeInsets.all(cardPadding),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Text(
            content,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
