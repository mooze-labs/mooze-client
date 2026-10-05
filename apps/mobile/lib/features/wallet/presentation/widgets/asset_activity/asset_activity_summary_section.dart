import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/asset_activity_summary.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_activity_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Received / Sent / Balance / Transactions as a single horizontal metrics
/// strip. Values are numeric only — the asset (and therefore the unit) is
/// fixed for the whole screen, so repeating it per metric would be noise.
class AssetSummarySection extends ConsumerWidget {
  final Asset asset;

  const AssetSummarySection({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hidden = ref.watch(isVisibleProvider);
    final locale = ref.watch(localeStringProvider);
    final summary =
        ref.watch(assetActivityProvider(asset)).valueOrNull ??
        AssetActivitySummary.empty(asset);

    String amount(BigInt value) =>
        hidden ? '••••' : asset.formatAmount(value.toInt(), locale: locale);
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: AssetSummaryStrip(
        metrics: [
          AssetSummaryMetric(
            icon: Icons.arrow_downward,
            iconColor: context.colors.positiveColor,
            value: amount(summary.totalReceived),
            label: t.asset_activity_received_total,
          ),
          AssetSummaryMetric(
            icon: Icons.arrow_upward,
            iconColor: context.colors.textSecondary,
            value: amount(summary.totalSent),
            label: t.asset_activity_sent_total,
          ),
          AssetSummaryMetric(
            icon: Icons.format_list_bulleted,
            iconColor: context.colors.primaryColor,
            value: '${summary.transactionCount}',
            label: t.asset_activity_transactions,
          ),
        ],
      ),
    );
  }
}
