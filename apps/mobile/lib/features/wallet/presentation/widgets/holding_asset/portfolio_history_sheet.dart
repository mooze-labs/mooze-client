import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/portfolio_history_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_chart.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_period_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_selection.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/expanding_glass_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/percentage_variation_display.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Mask that replaces a hidden amount.
const String _mask = '•••••';

/// Opens the portfolio history sheet.
///
/// The sheet grows out of the nearest [GlassSheetOrigin] above [context],
/// for example the change chip of the balance, and floats above the bottom
/// edge of the screen (see [showExpandingGlassSheet]).
Future<void> showPortfolioHistorySheet(BuildContext context) {
  return showExpandingGlassSheet<void>(
    context,
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
    builder: (_) => const PortfolioHistorySheet(),
  );
}

/// Floating glass sheet with the history of the portfolio (see
/// [portfolioHistoryProvider]): the value, its change over the period, the
/// chart, the period filters, and the open, high, and low of the period.
///
/// A scrub shows the value, the change, and the time of the point under the
/// finger; a range shows the value at its end and the change and the time
/// between its two points. A note says what the values are: the current
/// holdings at the prices of each moment.
///
/// The sheet opens on the 1D chart that the balance hero keeps computed, as
/// a market sheet opens from its cache, and refreshes the histories behind
/// it in the background. Before any chart exists, the plot is empty with a
/// loading pill, never a skeleton. A period that loads keeps the last
/// chart, dimmed, with a loading pill. A refresh waits while the user holds
/// a selection. A hidden balance masks the money; the line and the
/// percentages stay.
///
/// The widget is the sheet content. [showPortfolioHistorySheet] puts it on
/// the glass.
class PortfolioHistorySheet extends ConsumerStatefulWidget {
  const PortfolioHistorySheet({super.key});

  @override
  ConsumerState<PortfolioHistorySheet> createState() =>
      _PortfolioHistorySheetState();
}

class _PortfolioHistorySheetState extends ConsumerState<PortfolioHistorySheet> {
  MarketPeriod _period = MarketPeriod.day;
  final ValueNotifier<MarketSelection?> _selection = ValueNotifier(null);

  /// The history on screen and its period. While a new period loads, they
  /// still belong to the period before.
  PortfolioHistory? _shown;
  MarketPeriod _shownPeriod = MarketPeriod.day;

  @override
  void initState() {
    super.initState();
    _selection.addListener(_onSelection);
    // After the first frame: the refresh changes providers, which the
    // widget lifecycle must not do.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refreshPortfolioHistory(ref, _period);
    });
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
    final history = ref.watch(portfolioHistoryProvider(_period));
    // `isVisibleProvider` is true when the balance is hidden.
    final hidden = ref.watch(isVisibleProvider);
    final currency = ref.watch(currencySymbolProvider);
    final number = NumberFormat(
      '#,##0.00',
      Localizations.localeOf(context).toString(),
    );
    String money(double value) => hidden ? _mask : number.format(value);

    // A selection holds the chart still. A refresh of the same period waits
    // until the user lets go.
    final holding = _selection.value != null && _shownPeriod == _period;
    if (history.valueOrNull case final latest? when !holding) {
      _shown = latest;
      _shownPeriod = _period;
    }
    final failed = history.hasError && !history.isLoading;
    final empty =
        history.hasValue && history.value == null && !history.isLoading;
    if (failed || empty) _shown = null;
    final shown = _shown;
    final values = shown?.values;
    final period = shown == null ? _period : _shownPeriod;
    final updating = history.isLoading && shown != null;

    var selection = _selection.value;
    if (values == null || !(selection?.fits(values.length) ?? true)) {
      selection = null;
    }
    DateTime timeOf(int index) =>
        marketPointTime(index, values!.length, period, shown!.end);

    final (double? value, double? start, String caption) = values == null
        ? (null, null, period.spokenName(t))
        : switch (selection) {
            MarketRange(:final from, :final to) => (
              values[to],
              values[from],
              _span(t, period.step * (to - from)),
            ),
            MarketPoint(:final index) => (
              values[index],
              values.first,
              formatMarketTime(context, timeOf(index), period, withHour: true),
            ),
            null => (values.last, values.first, period.spokenName(t)),
          };
    final percentage = value != null && start != null && start != 0
        ? (value - start) / start * 100
        : null;

    final trend = values == null ? 0.0 : values.last - values.first;
    final lineColor =
        values == null ||
            values.first == 0 ||
            ChangeChip.isFlat(trend / values.first * 100)
        ? context.colors.textSecondary
        : trend > 0
        ? context.colors.positiveColor
        : context.colors.negativeColor;

    final Widget chart;
    if (values != null) {
      chart = MarketChartUpdating(
        key: const ValueKey('chart'),
        updating: updating,
        child: MarketChart(
          klines: values,
          period: period,
          end: shown!.end,
          color: lineColor,
          selection: _selection,
          semanticsLabel: t.wallet_asset_chart_semantics(
            t.wallet_title,
            period.spokenName(t),
            '$currency ${money(values.first)}',
            '$currency ${money(values.last)}',
            ChangeChip.format(
              context,
              values.first == 0 ? 0 : trend / values.first * 100,
            ),
          ),
        ),
      );
    } else if (failed || empty) {
      chart = const MarketChartUnavailable(key: ValueKey('error'));
    } else {
      chart = const MarketChartLoading(key: ValueKey('loading'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSheetHeader(title: t.wallet_portfolio_history_title),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ValueLine(
                  currency: currency,
                  value: value == null ? null : money(value),
                  percentage: percentage,
                  change: value != null && start != null
                      ? '${_sign(percentage)}$currency '
                            '${money((value - start).abs())}'
                      : null,
                  caption: caption,
                  following: selection != null,
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
                  values: values,
                  format: (value) => '$currency ${money(value)}',
                ),
                const SizedBox(height: 16),
                _Note(text: t.wallet_portfolio_history_note),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Sign of a change, as [ChangeChip] shows it.
  static String _sign(double? percentage) =>
      percentage == null || ChangeChip.isFlat(percentage)
      ? ''
      : percentage > 0
      ? '+'
      : '−';

  /// Formats the time between two points, for example "5 horas", "3 dias",
  /// or "2 d 4 h".
  static String _span(AppLocalizations t, Duration elapsed) {
    final hours = elapsed.inHours;
    if (hours < 24) return t.wallet_asset_range_hours(hours);
    final days = hours ~/ 24;
    final rest = hours % 24;
    return rest == 0
        ? t.wallet_asset_range_days(days)
        : t.wallet_asset_range_days_hours(days, rest);
  }
}

/// The value with its muted currency, then the change chip, the change in
/// money, and the caption on one line that never wraps, so the sheet keeps
/// its height while the figures follow the finger.
class _ValueLine extends StatelessWidget {
  const _ValueLine({
    required this.currency,
    required this.value,
    required this.percentage,
    required this.change,
    required this.caption,
    required this.following,
  });

  final String currency;
  final String? value;
  final double? percentage;
  final String? change;
  final String caption;

  /// True while the figures follow a selection: the chip then shows each
  /// value at once.
  final bool following;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final secondary = textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final value = this.value;
    final percentage = this.percentage;
    final change = this.change;

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
                child: Text(
                  value ?? '—',
                  maxLines: 1,
                  style: textTheme.headlineLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (percentage != null) ...[
              ChangeChip(percentage: percentage, animateValue: !following),
              const SizedBox(width: 8),
            ],
            if (change != null) ...[
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(change, style: secondary, maxLines: 1),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                caption,
                style: secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The open, high, and low of the period in one row, split by hairlines.
class _PeriodStats extends StatelessWidget {
  const _PeriodStats({required this.values, required this.format});

  final List<double>? values;
  final String Function(double value) format;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final values = this.values;
    String valueOf(double Function(List<double>) pick) =>
        values == null ? '—' : format(pick(values));

    final stats = [
      (t.wallet_asset_stats_open, valueOf((v) => v.first)),
      (
        t.wallet_asset_stats_high,
        valueOf((v) => v.reduce((a, b) => a > b ? a : b)),
      ),
      (
        t.wallet_asset_stats_low,
        valueOf((v) => v.reduce((a, b) => a < b ? a : b)),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 32,
              color: AppSurfaces.hairline(context),
            ),
          Expanded(
            child: MergeSemantics(
              child: Column(
                children: [
                  Text(
                    stats[i].$1,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        stats[i].$2,
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
            ),
          ),
        ],
      ],
    );
  }
}

/// A short note with an info icon: what the values of the sheet are.
class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: PixIcon(PixIcons.info, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
