import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/period_selector_widget.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/services/price_service.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

class AssetChartWidget extends ConsumerStatefulWidget {
  final Asset asset;
  final TimePeriod selectedPeriod;

  const AssetChartWidget({
    super.key,
    required this.asset,
    required this.selectedPeriod,
  });

  @override
  ConsumerState<AssetChartWidget> createState() => _AssetChartWidgetState();
}

class _AssetChartWidgetState extends ConsumerState<AssetChartWidget> {
  double? _touchedPrice;
  int? _touchedIndex;

  AssetPriceHistoryParams _getParamsForPeriod(TimePeriod period, Asset asset) {
    switch (period) {
      case TimePeriod.day:
        return AssetPriceHistoryParams(
          asset: asset,
          interval: KlineInterval.oneHour,
          periodInDays: 1,
        );
      case TimePeriod.week:
        return AssetPriceHistoryParams(
          asset: asset,
          interval: KlineInterval.fourHours,
          periodInDays: 7,
        );
      case TimePeriod.month:
        return AssetPriceHistoryParams(
          asset: asset,
          interval: KlineInterval.oneDay,
          periodInDays: 30,
        );
    }
  }

  Duration _getIntervalDuration(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return const Duration(hours: 1);
      case TimePeriod.week:
        return const Duration(hours: 4);
      case TimePeriod.month:
        return const Duration(days: 1);
    }
  }

  DateTime _getTimestampForIndex(int index, int totalPoints, TimePeriod period) {
    final now = DateTime.now();
    final intervalMs = _getIntervalDuration(period).inMilliseconds;
    final offsetMs = (totalPoints - 1 - index) * intervalMs;
    return now.subtract(Duration(milliseconds: offsetMs));
  }

  String _formatAxisTime(DateTime time, TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return DateFormat('HH:mm').format(time);
      case TimePeriod.week:
      case TimePeriod.month:
        return DateFormat('dd/MM').format(time);
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(price);
    }
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(price);
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return '1D';
      case TimePeriod.week:
        return '7D';
      case TimePeriod.month:
        return '1M';
    }
  }

  @override
  void didUpdateWidget(AssetChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _touchedPrice = null;
      _touchedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = _getParamsForPeriod(widget.selectedPeriod, widget.asset);
    final priceHistory = ref.watch(assetPriceHistoryWithPeriodProvider(params));
    final onSurface = context.colorScheme.onSurface;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.1), width: 1),
      ),
      child: priceHistory.when(
        data: (data) => data.fold(
          (err) => _buildErrorChart(context),
          (klines) => _buildSuccessChart(context, klines),
        ),
        error: (_, _) => _buildErrorChart(context),
        loading: () => _buildLoadingChart(context),
      ),
    );
  }

  Widget _buildSuccessChart(BuildContext context, List<double> klines) {
    if (klines.isEmpty) return _buildErrorChart(context);

    final isPositive = klines.last >= klines.first;
    final lineColor = isPositive
        ? context.colors.positiveColor
        : context.colors.negativeColor;
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    final activeIndex = _touchedIndex ?? klines.length - 1;
    final displayPrice = _touchedPrice ?? klines.last;
    final displayTime = _getTimestampForIndex(
      activeIndex.clamp(0, klines.length - 1),
      klines.length,
      widget.selectedPeriod,
    );

    final minY = klines.reduce((a, b) => a < b ? a : b);
    final maxY = klines.reduce((a, b) => a > b ? a : b);
    final yRange = maxY - minY;
    final yPadding = yRange == 0 ? 100.0 : yRange * 0.1;

    final spots = klines
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    // 5 evenly spaced x-axis labels
    const labelCount = 5;
    final labelIndices = <int>{};
    if (klines.length > 1) {
      for (int i = 0; i < labelCount; i++) {
        labelIndices.add(
          ((klines.length - 1) * i / (labelCount - 1)).round(),
        );
      }
    } else {
      labelIndices.add(0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gráfico - ${_getPeriodLabel(widget.selectedPeriod)}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(displayPrice),
                  style: textTheme.titleSmall?.copyWith(
                    color: lineColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatAxisTime(displayTime, widget.selectedPeriod),
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minY - yPadding,
              maxY: maxY + yPadding,
              clipData: const FlClipData.all(),
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent ||
                      event is FlPanEndEvent ||
                      event is FlPointerExitEvent) {
                    setState(() {
                      _touchedPrice = null;
                      _touchedIndex = null;
                    });
                    return;
                  }
                  final spots = response?.lineBarSpots;
                  if (spots != null && spots.isNotEmpty) {
                    setState(() {
                      _touchedPrice = spots.first.y;
                      _touchedIndex = spots.first.x.round();
                    });
                  }
                },
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((i) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: lineColor.withValues(alpha: 0.5),
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                      ),
                      FlDotData(
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: colorScheme.surface,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
                // Tooltip is handled in the header row above; return null per
                // spot to satisfy the required same-length contract.
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                  getTooltipItems: (spots) =>
                      spots.map((_) => null).toList(),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: yRange == 0 ? 100 : yRange / 4,
                verticalInterval: (klines.length / 6).ceilToDouble(),
                getDrawingHorizontalLine: (_) => FlLine(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.round();
                      if (!labelIndices.contains(idx)) {
                        return const SizedBox.shrink();
                      }
                      final time = _getTimestampForIndex(
                        idx,
                        klines.length,
                        widget.selectedPeriod,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _formatAxisTime(time, widget.selectedPeriod),
                          style: textTheme.bodySmall?.copyWith(
                            color: context.colors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: lineColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        lineColor.withValues(alpha: 0.25),
                        lineColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingChart(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.baseColor,
      highlightColor: context.colors.highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: context.colors.baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.baseColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChart(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gráfico Indisponível',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error.withValues(alpha: 0.7),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível carregar o gráfico',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
