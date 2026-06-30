import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// On-chain confirmation progress banner. [confirmations] is null while the
/// current block height is still being fetched, in which case a neutral
/// "verifying" state is shown.
class ConfirmationBanner extends StatelessWidget {
  final int? confirmations;

  const ConfirmationBanner({super.key, required this.confirmations});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final confirmations = this.confirmations;
    final isFullyConfirmed = confirmations != null && confirmations >= 6;

    String displayText;
    Color displayColor;

    if (confirmations == null) {
      displayText = t.common_verifying;
      displayColor = Theme.of(context).colorScheme.outline;
    } else if (confirmations >= 6) {
      displayText = t.tx_detail_confirmations_full;
      displayColor = context.colors.positiveColor;
    } else {
      displayText = t.tx_detail_confirmations_progress(confirmations);
      displayColor = context.appColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: displayColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFullyConfirmed ? Icons.check_circle : Icons.schedule,
              size: 18,
              color: displayColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.tx_detail_confirmations,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayText,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: displayColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
