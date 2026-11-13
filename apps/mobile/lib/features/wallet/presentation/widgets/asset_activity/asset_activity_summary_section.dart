import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/asset_activity_summary.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_activity_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';

/// Received, sent, and the number of transactions, side by side in a glass
/// lens. The amounts carry no unit: the asset of the sheet fixes it.
///
/// The arrows of the app tell the direction, and the green well marks what
/// came in.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AssetSectionTitle(t.asset_activity_summary_title),
        const SizedBox(height: 8),
        AssetGlassLens(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
          child: AssetSummaryStrip(
            metrics: [
              AssetSummaryMetric(
                icon: PixIcons.receive,
                tone: PixTone.positive,
                value: amount(summary.totalReceived),
                label: t.asset_activity_received_total,
              ),
              AssetSummaryMetric(
                icon: PixIcons.send,
                value: amount(summary.totalSent),
                label: t.asset_activity_sent_total,
              ),
              AssetSummaryMetric(
                icon: PixIcons.history,
                value: '${summary.transactionCount}',
                label: t.asset_activity_transactions,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
