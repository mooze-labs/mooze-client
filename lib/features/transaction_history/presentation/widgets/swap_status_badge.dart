import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/transaction_indicator_badge.dart';

/// Centered swap medallion with a status caption underneath — the header for
/// swap, submarine and refund transactions.
class SwapStatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const SwapStatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TransactionIndicatorBadge(icon: icon, color: color, size: 72),
        const SizedBox(height: 14),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
