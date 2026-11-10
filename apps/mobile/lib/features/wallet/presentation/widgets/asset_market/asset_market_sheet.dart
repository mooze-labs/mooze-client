import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_history_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_chart.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_period_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_selection.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/expanding_glass_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/percentage_variation_display.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/shared/widgets/motion/animated_amount.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Opens the market sheet of [asset].
///
/// The sheet grows out of the nearest [GlassSheetOrigin] above [context],
/// for example the tapped asset row, and floats above the bottom edge of
/// the screen (see [showExpandingGlassSheet]).
Future<void> showAssetMarketSheet(
  BuildContext context, {
  required Asset asset,
}) {
  return showExpandingGlassSheet<void>(
    context,
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
    builder: (_) => AssetMarketSheet(asset: asset),
  );
}

/// Floating glass sheet with the market of one asset: the live price, its
/// change over the selected period, the price chart, the period control,
/// and the open, high, and low of the period.
///
/// Data: the chart shows the cached history of the period at once, with
/// no skeleton, and refreshes it in the background (see
/// [marketHistoryProvider]). A refresh that arrives while the user scrubs
/// or holds a range waits until the selection ends, so the chart never
/// changes under the finger.
///
/// Selection: a scrub shows the price, the change, and the time of the
/// point under the finger in the price hero. A range shows the price at
/// its end, the change and the time between its two points, and both
/// points with their prices and times. The values come from real points
/// of the history.
///
/// A period without a cached history shows the loading state at once: the
/// last chart stays, dims, and stops taking touches, and a small pill over
/// it says that the chart is loading. Only the selected period can end the
/// loading state. A failed load without a cached history shows the
/// unavailable state with a retry button.
///
/// The widget is the sheet content. [showAssetMarketSheet] puts it on the
/// glass.
class AssetMarketSheet extends ConsumerStatefulWidget {
  const AssetMarketSheet({super.key, required this.asset});

  final Asset asset;

  @override
  ConsumerState<AssetMarketSheet> createState() => _AssetMarketSheetState();
}

class _AssetMarketSheetState extends ConsumerState<AssetMarketSheet> {
  MarketPeriod _period = MarketPeriod.day;
  final ValueNotifier<MarketSelection?> _selection = ValueNotifier(null);

  /// The history on screen and its period. While a period without a cache
  /// loads, they still belong to the period before.
  CachedPriceHistory? _shown;
  MarketPeriod _shownPeriod = MarketPeriod.day;

  @override
  void initState() {
    super.initState();
    _selection.addListener(_onSelection);
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  void _onSelection() => setState(() {});

  void _selectPeriod(MarketPeriod period) {
    _selection.value = null;
    setState(() => _period = period);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final asset = widget.asset;
    final key = (asset, _period);
    final history = ref.watch(marketHistoryProvider(key));
    final spotPrice = ref.watch(
      priceQuotesProvider.select((s) => s.priceFor(asset)),
    );
    final currency = ref.watch(currencySymbolProvider);
    final isOffline = ref.watch(isUsingCacheProvider);
    final numberFormat = NumberFormat(
      '#,##0.00',
      Localizations.localeOf(context).toString(),
    );
    String money(double value) => '$currency ${numberFormat.format(value)}';

    // A selection holds the chart still. A refresh of the same period waits
    // until the user lets go.
    final holding = _selection.value != null && _shownPeriod == _period;
    if (history.history case final latest? when !holding) {
      _shown = latest;
      _shownPeriod = _period;
    }
    // A failed period drops the chart of the period before, so a retry
    // shows the skeleton and not a chart of another period.
    if (history.failed) _shown = null;
    final shown = _shown;
    final klines = shown?.prices;
    final period = shown == null ? _period : _shownPeriod;
    final updating =
        history.history == null && history.loading && shown != null;

    var selection = _selection.value;
    if (klines == null || !(selection?.fits(klines.length) ?? true)) {
      selection = null;
    }

    final livePrice = spotPrice ?? klines?.last;
    DateTime timeOf(int index) =>
        marketPointTime(index, klines!.length, period, shown!.fetchedAt);
    String timeLabel(int index) =>
        formatMarketTime(context, timeOf(index), period, withHour: true);

    final (price, start, caption) = switch (selection) {
      MarketRange(:final from, :final to) => (
        klines![to],
        klines[from],
        _elapsed(t, period.step * (to - from)),
      ),
      MarketPoint(:final index) => (
        klines![index],
        klines.first,
        timeLabel(index),
      ),
      null => (livePrice, klines?.first, period.spokenName(t)),
    };
    final percentage = price != null && start != null && start != 0
        ? (price - start) / start * 100
        : null;

    final trend = klines == null ? 0.0 : klines.last - klines.first;
    final lineColor =
        klines == null || ChangeChip.isFlat(trend / klines.first * 100)
        ? context.colors.textSecondary
        : trend > 0
        ? context.colors.positiveColor
        : context.colors.negativeColor;

    final Widget chart;
    if (klines != null) {
      chart = MarketChartUpdating(
        key: const ValueKey('chart'),
        updating: updating,
        child: MarketChart(
          klines: klines,
          period: period,
          end: shown!.fetchedAt,
          color: lineColor,
          selection: _selection,
          semanticsLabel: t.wallet_asset_chart_semantics(
            asset.name,
            period.spokenName(t),
            money(klines.first),
            money(livePrice ?? klines.last),
            ChangeChip.format(
              context,
              ((livePrice ?? klines.last) - klines.first) / klines.first * 100,
            ),
          ),
        ),
      );
    } else if (history.failed) {
      chart = MarketChartUnavailable(
        key: const ValueKey('error'),
        onRetry: () => ref.read(marketHistoryProvider(key).notifier).refresh(),
      );
    } else {
      chart = const MarketChartSkeleton(key: ValueKey('loading'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSheetHeader(
          title: asset.name,
          subtitle: asset.ticker,
          leading: ExcludeSemantics(
            child: SvgPicture.asset(asset.iconPath, width: 36, height: 36),
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isOffline) ...[
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _OfflineBadge(),
                  ),
                  const SizedBox(height: 12),
                ],
                // The range details add height above the chart. The sheet
                // grows upward from its fixed bottom edge, so the chart
                // stays under the finger.
                _SizeChange(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PriceHero(
                        currency: currency,
                        price: price,
                        percentage: percentage,
                        change: price != null && start != null
                            ? price - start
                            : null,
                        caption: caption,
                        scrubbing: selection != null,
                        failed: history.failed,
                        numberFormat: numberFormat,
                        onClear: selection is MarketRange
                            ? () => _selection.value = null
                            : null,
                      ),
                      if (selection case MarketRange(:final from, :final to))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _RangeEnds(
                            start: (money(klines![from]), timeLabel(from)),
                            end: (money(klines[to]), timeLabel(to)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                MarketChartSwitcher(child: chart),
                const SizedBox(height: 16),
                MarketPeriodSelector(
                  selected: _period,
                  onChanged: _selectPeriod,
                ),
                const SizedBox(height: 20),
                _PeriodStats(
                  klines: klines,
                  failed: history.failed,
                  format: money,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Formats the time between two points, for example "5 horas", "3 dias",
  /// or "2 d 4 h".
  static String _elapsed(AppLocalizations t, Duration elapsed) {
    final hours = elapsed.inHours;
    if (hours < 24) return t.wallet_asset_range_hours(hours);
    final days = hours ~/ 24;
    final rest = hours % 24;
    return rest == 0
        ? t.wallet_asset_range_days(days)
        : t.wallet_asset_range_days_hours(days, rest);
  }
}

/// Animates size changes of [child] over [Motion.durationFast]. The bottom
/// edge stays in place. With reduced motion, the size changes at once.
class _SizeChange extends StatelessWidget {
  const _SizeChange({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // AnimatedSize does not accept a zero duration.
    if (Motion.isReduced(context)) return child;
    return AnimatedSize(
      duration: Motion.durationFast,
      curve: Motion.curveMove,
      alignment: Alignment.bottomCenter,
      child: child,
    );
  }
}

/// The start and the end of a range: a label, the price, and the time of
/// each point, with an arrow between them.
class _RangeEnds extends StatelessWidget {
  const _RangeEnds({required this.start, required this.end});

  /// Price and time of each point.
  final (String, String) start;
  final (String, String) end;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: _RangeEnd(
              label: t.wallet_asset_range_start,
              value: start,
              alignment: CrossAxisAlignment.start,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: context.colors.textSecondary,
            ),
          ),
          Expanded(
            child: _RangeEnd(
              label: t.wallet_asset_range_end,
              value: end,
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeEnd extends StatelessWidget {
  const _RangeEnd({
    required this.label,
    required this.value,
    required this.alignment,
  });

  final String label;
  final (String, String) value;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final secondary = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
    );
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(label, style: secondary),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value.$1,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(value.$2, style: secondary, maxLines: 1),
      ],
    );
  }
}

/// The price, its change from a reference point, and a caption: the period
/// name, the time of the scrubbed point, or the length of a range.
///
/// The currency symbol is muted, so the figure leads. The live price
/// animates with [AnimatedAmount]. While the chart has a selection, the
/// figures follow the finger without animation.
class _PriceHero extends StatelessWidget {
  const _PriceHero({
    required this.currency,
    required this.price,
    required this.percentage,
    required this.change,
    required this.caption,
    required this.scrubbing,
    required this.failed,
    required this.numberFormat,
    this.onClear,
  });

  final String currency;
  final double? price;
  final double? percentage;
  final double? change;
  final String caption;
  final bool scrubbing;
  final bool failed;
  final NumberFormat numberFormat;

  /// Clears the range. Null hides the clear button.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final price = this.price;
    final percentage = this.percentage;
    final change = this.change;
    final figureStyle = textTheme.headlineLarge?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final secondaryStyle = textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final Widget figure;
    if (price == null) {
      figure = failed
          ? Text('N/A', style: figureStyle)
          : const SkeletonShimmer(child: SkeletonBox(width: 160, height: 36));
    } else if (scrubbing) {
      figure = Text(numberFormat.format(price), style: figureStyle);
    } else {
      figure = AnimatedAmount(
        text: numberFormat.format(price),
        value: price,
        style: figureStyle,
      );
    }

    final Widget chip;
    if (percentage != null) {
      chip = ChangeChip(percentage: percentage, animateValue: !scrubbing);
    } else if (failed) {
      chip = const UnavailableChangeChip();
    } else {
      chip = const LoadingChangeChip();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              currency,
              style: textTheme.titleLarge?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: figure,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // One line that never wraps, so the sheet keeps its height while
        // the figures follow a scrub. The amount scales down before it
        // would overflow, and the caption shortens with an ellipsis.
        Row(
          children: [
            chip,
            if (change != null && percentage != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${_sign(percentage)}$currency '
                    '${numberFormat.format(change.abs())}',
                    style: secondaryStyle,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                caption,
                style: secondaryStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear case final onClear?) ...[
              const Spacer(),
              IconButton(
                tooltip: AppLocalizations.of(context).wallet_asset_range_clear,
                onPressed: onClear,
                icon: PixIcon(
                  PixIcons.close,
                  size: 18,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Sign of a change, as [ChangeChip] shows it.
  static String _sign(double percentage) => ChangeChip.isFlat(percentage)
      ? ''
      : percentage > 0
      ? '+'
      : '−';
}

/// The open, high, and low of the period in one row, split by hairlines.
class _PeriodStats extends StatelessWidget {
  const _PeriodStats({
    required this.klines,
    required this.failed,
    required this.format,
  });

  final List<double>? klines;
  final bool failed;
  final String Function(double value) format;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final klines = this.klines;
    final hairline = AppSurfaces.hairline(context);

    String? valueOf(double Function(List<double>) pick) {
      if (klines != null) return format(pick(klines));
      return failed ? 'N/A' : null;
    }

    final stats = [
      (t.wallet_asset_stats_open, valueOf((k) => k.first)),
      (
        t.wallet_asset_stats_high,
        valueOf((k) => k.reduce((a, b) => a > b ? a : b)),
      ),
      (
        t.wallet_asset_stats_low,
        valueOf((k) => k.reduce((a, b) => a < b ? a : b)),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) Container(width: 1, height: 32, color: hairline),
          Expanded(
            child: _Stat(label: stats[i].$1, value: stats[i].$2),
          ),
        ],
      ],
    );
  }
}

/// One stat: a label and a value. A null value shows a skeleton.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return MergeSemantics(
      child: Column(
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (value == null)
            const SkeletonShimmer(child: SkeletonBox(width: 64, height: 16))
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A warning pill: the prices come from the offline cache.
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final warning = context.appColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: warning, size: 14),
          const SizedBox(width: 6),
          Text(
            t.wallet_asset_offline,
            style: context.textTheme.labelSmall?.copyWith(
              color: warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
