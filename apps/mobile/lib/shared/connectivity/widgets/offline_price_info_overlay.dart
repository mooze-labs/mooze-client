import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_sheet_badge.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../providers/cache_info_provider.dart';

/// Opens the [OfflinePriceInfoSheet] from the offline indicator.
class OfflinePriceInfoOverlay {
  static void show(BuildContext context) {
    showFloatingGlassSheet<void>(
      context,
      builder: (_) => const OfflinePriceInfoSheet(),
    );
  }
}

/// Floating glass sheet that explains the offline mode: the prices the app
/// shows are the last ones it saved, with their age.
class OfflinePriceInfoSheet extends ConsumerWidget {
  const OfflinePriceInfoSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final cacheInfo = ref.watch(cacheInfoProvider);

    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSheetHeader(
            title: t.offline_price_title,
            leading: GlassSheetBadge(
              icon: PixIcons.offline,
              color: context.appColors.warning,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Semantics(
                      header: true,
                      child: Text(
                        t.offline_price_saved,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  cacheInfo.when(
                    data: (list) => list.isEmpty
                        ? _Message(t.offline_price_empty)
                        : _PriceList(list),
                    loading: () => const _PriceListSkeleton(),
                    error: (_, _) => _Message(t.offline_price_load_error),
                  ),
                  const SizedBox(height: 20),
                  _Hint(t.offline_price_hint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A glass lens that holds rows split by inset hairlines.
class _Lens extends StatelessWidget {
  const _Lens({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GlassStyle.of(context).lensFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const PanelDivider(indent: _PriceRow.textInset),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _PriceList extends StatelessWidget {
  const _PriceList(this.list);

  final List<AssetCacheInfo> list;

  @override
  Widget build(BuildContext context) {
    return _Lens(rows: [for (final info in list) _PriceRow(info)]);
  }
}

/// One saved price: the asset, the age of the price, the price, and how
/// fresh it is.
class _PriceRow extends StatelessWidget {
  const _PriceRow(this.info);

  static const double iconSize = 32;
  static const double padding = 16;

  /// Distance from the lens edge to the row text. Dividers start here.
  static const double textInset = padding + iconSize + 12;

  final AssetCacheInfo info;

  /// The age of the price, as the minutes, hours, or days it has.
  static String _age(AppLocalizations t, AssetCacheInfo info) {
    if (!info.hasCache) return t.offline_price_no_cache;
    return switch (info.ageInMinutes) {
      null => t.offline_price_age_unknown,
      final minutes when minutes < 60 => t.developer_time_minutes_ago(minutes),
      final minutes when minutes < 1440 => t.developer_time_hours_ago(
        (minutes / 60).round(),
      ),
      final minutes => t.developer_time_days_ago((minutes / 1440).round()),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final price = info.lastPrice;
    final numberFormat = NumberFormat(
      '#,##0.00',
      Localizations.localeOf(context).toString(),
    );

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              info.asset.iconPath,
              width: iconSize,
              height: iconSize,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.asset.displayName,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _age(t, info),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price == null
                      ? '—'
                      : '${info.currencySymbol} ${numberFormat.format(price)}',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (info.hasCache && info.ageInMinutes != null) ...[
                  const SizedBox(height: 4),
                  _Freshness(ageInMinutes: info.ageInMinutes!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// How fresh a saved price is: a dot in the tone of the age and its label.
/// The label carries the meaning, so the color is not the only signal.
class _Freshness extends StatelessWidget {
  const _Freshness({required this.ageInMinutes});

  final int ageInMinutes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (color, label) = switch (ageInMinutes) {
      < 5 => (context.colors.positiveColor, t.offline_price_fresh),
      < 30 => (context.appColors.warning, t.offline_price_old),
      _ => (context.colors.negativeColor, t.offline_price_very_old),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Three rows of skeletons while the saved prices load.
class _PriceListSkeleton extends StatelessWidget {
  const _PriceListSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row() => const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _PriceRow.padding,
        vertical: 14,
      ),
      child: Row(
        children: [
          SkeletonBox(
            width: _PriceRow.iconSize,
            height: _PriceRow.iconSize,
            radius: _PriceRow.iconSize / 2,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 96, height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 64, height: 12),
              ],
            ),
          ),
          SkeletonBox(width: 88, height: 14),
        ],
      ),
    );
    return SkeletonShimmer(child: _Lens(rows: [row(), row(), row()]));
  }
}

/// A short note inside the sheet, in the secondary text color.
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

/// A note with an info icon, as the hint of a [GlassInfoSheet].
class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: PixIcon(
            PixIcons.info,
            size: 16,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
