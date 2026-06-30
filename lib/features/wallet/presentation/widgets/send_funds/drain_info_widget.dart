import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/drain_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';

class DrainInfoWidget extends ConsumerWidget {
  const DrainInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);

    if (!isDrainTransaction) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.wallet_send_drain_title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t.wallet_send_drain_body(selectedAsset.name),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.wallet_send_drain_ready,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
