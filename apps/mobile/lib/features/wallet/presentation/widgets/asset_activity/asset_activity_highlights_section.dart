import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/asset_activity_summary.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_activity_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The highlights of the history and its timeline, in two glass lenses:
///
/// - Highlights: the volume moved, then the largest receive and the largest
///   send.
/// - Movements: the first and the last transaction, on a rail.
///
/// Everything comes from the transaction history. No investment framing: no
/// profit, no cost basis, no performance.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AssetSectionTitle(t.asset_activity_highlights_title),
        const SizedBox(height: 8),
        AssetGlassLens(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _VolumeRow(
                label: t.asset_activity_total_volume,
                value: amount(summary.totalVolume),
              ),
              const SizedBox(height: 14),
              const AssetPanelDivider(),
              const SizedBox(height: 12),
              _StatisticRow(
                icon: PixIcons.receive,
                tone: PixTone.positive,
                label: t.asset_activity_largest_receive,
                value: amount(summary.largestReceive),
              ),
              const SizedBox(height: 12),
              _StatisticRow(
                icon: PixIcons.send,
                label: t.asset_activity_largest_send,
                value: amount(summary.largestSend),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AssetSectionTitle(t.asset_activity_section_title),
        const SizedBox(height: 8),
        AssetGlassLens(
          child: Column(
            children: [
              _TimelineEntry(
                icon: PixIcons.calendar,
                label: t.asset_activity_first,
                value: first != null ? dateFmt.format(first) : '—',
                isFirst: true,
                isLast: false,
              ),
              _TimelineEntry(
                icon: PixIcons.clock,
                label: t.asset_activity_last,
                value: last != null ? dateTimeFmt.format(last) : '—',
                isFirst: false,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The headline of the highlights: the volume moved, by its well.
class _VolumeRow extends StatelessWidget {
  final String label;
  final String value;

  const _VolumeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          const ExcludeSemantics(child: PixIconWell(icon: PixIcons.exchange)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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

/// A statistic: its well and label on the left, its amount on the right.
class _StatisticRow extends StatelessWidget {
  final PixIconData icon;
  final PixTone tone;
  final String label;
  final String value;

  const _StatisticRow({
    required this.icon,
    required this.label,
    required this.value,
    this.tone = PixTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          ExcludeSemantics(
            child: PixIconWell(icon: icon, tone: tone, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style: context.textTheme.titleSmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of the timeline: a rail on the left (the well and its connectors)
/// and the event on the right. The rail stops at the first and the last
/// well, so it reads as one line.
class _TimelineEntry extends StatelessWidget {
  final PixIconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _TimelineEntry({
    required this.icon,
    required this.label,
    required this.value,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final rail = AppSurfaces.hairline(context);
    Widget connector(bool hidden) => Expanded(
      child: Center(
        child: Container(width: 2, color: hidden ? Colors.transparent : rail),
      ),
    );

    return MergeSemantics(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  connector(isFirst),
                  ExcludeSemantics(child: PixIconWell(icon: icon, size: 36)),
                  connector(isLast),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: isFirst ? 0 : 8,
                  bottom: isLast ? 0 : 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
