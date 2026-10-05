import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/asset_activity_summary.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_activity_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A single card that unifies the asset's key stats and its movement timeline:
///
///   • Total volume (the headline metric)
///   • Largest receive / Largest send
///   • Movements timeline — first and last transaction
///
/// Everything derives from the existing transaction history; no investment
/// framing. The timeline lives inside the same card so the section reads as
/// one cohesive analytics block.
class AssetHighlightsSection extends ConsumerWidget {
  final Asset asset;

  const AssetHighlightsSection({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hidden = ref.watch(isVisibleProvider);
    final locale = ref.watch(localeStringProvider);

    final summary =
        ref.watch(assetActivityProvider(asset)).valueOrNull ??
        AssetActivitySummary.empty(asset);

    String amount(BigInt value) {
      if (hidden) return '••••••';
      return WalletHolding.formatBalance(value, asset, locale);
    }

    final dateFmt = DateFormat('dd MMM yyyy', locale);
    final dateTimeFmt = DateFormat('dd MMM yyyy, HH:mm', locale);
    final first = summary.firstActivity;
    final last = summary.lastActivity;

    final colorScheme = context.colorScheme;
    final divider = context.colors.textSecondary.withValues(alpha: .12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.asset_activity_total_volume,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount(summary.totalVolume),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: divider),
          const SizedBox(height: 16),

          _StatisticRow(
            label: t.asset_activity_largest_receive,
            value: amount(summary.largestReceive),
            valueColor: context.colors.positiveColor,
          ),
          const SizedBox(height: 14),
          _StatisticRow(
            label: t.asset_activity_largest_send,
            value: amount(summary.largestSend),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: divider),
          const SizedBox(height: 16),

          _TimelineEntry(
            icon: Icons.flag_outlined,
            iconColor: context.colors.primaryColor,
            label: t.asset_activity_first,
            value: first != null ? dateFmt.format(first) : '—',
            isFirst: true,
            isLast: false,
          ),
          _TimelineEntry(
            icon: Icons.bolt_outlined,
            iconColor: context.colors.positiveColor,
            label: t.asset_activity_last,
            value: last != null ? dateTimeFmt.format(last) : '—',
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StatisticRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatisticRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// A single timeline row: a marker rail on the left (node + connectors) and the
/// event text inline on the right. The connector segments above/below the node
/// are suppressed at the ends so the rail reads as one continuous line.
class _TimelineEntry extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _TimelineEntry({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final connector = assetActivitySeparatorColor(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : connector,
                    ),
                  ),
                ),
                AssetIconChip(icon: icon, color: iconColor, size: 32),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : connector,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirst ? 4 : 12,
                bottom: isLast ? 4 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
