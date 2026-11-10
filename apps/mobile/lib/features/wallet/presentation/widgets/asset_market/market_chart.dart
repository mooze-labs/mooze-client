import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_period_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_selection.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Returns the time of the point at [index] of a history with [length]
/// points whose last point belongs to [end].
DateTime marketPointTime(
  int index,
  int length,
  MarketPeriod period,
  DateTime end,
) => end.subtract(period.step * (length - 1 - index));

/// Formats [time] for [period]: the hour for 1D, the date and the hour for
/// 7D, and the date for 1M.
String formatMarketTime(
  BuildContext context,
  DateTime time,
  MarketPeriod period, {
  bool withHour = false,
}) {
  final locale = Localizations.localeOf(context).toString();
  return switch (period) {
    MarketPeriod.day => DateFormat.Hm(locale).format(time),
    MarketPeriod.week when withHour => DateFormat.MMMd(
      locale,
    ).add_Hm().format(time),
    _ => DateFormat.MMMd(locale).format(time),
  };
}

/// The hero chart of the market sheet. It sits on the sheet glass, without
/// a card of its own.
///
/// Parts: the price line with a soft area fill, dashed horizontal guides, a
/// dashed reference line at the start price, and three time labels.
///
/// The chart writes what the user picks to [selection]:
/// - A horizontal drag scrubs: a ring marks the point under the finger. The
///   end of the touch clears the point.
/// - A long press starts a range at the pressed point, and the drag that
///   follows places the second marker. The range stays after the finger
///   lifts: a drag moves the nearest marker, a long press starts a new
///   range, and a tap clears it.
///
/// Each new point plays a selection click, at most every [hapticGap]. The
/// start of a range plays a light impact. While a range is shown, vertical
/// drags on the chart move its markers too, so they never close the sheet.
///
/// Motion:
/// - First show: the chart reveals from left to right over
///   [Motion.durationChartDraw].
/// - New [klines]: the line morphs to the new data over
///   [Motion.durationEmphasis].
/// - Range: the shaded area and the markers fade in and out over
///   [Motion.durationFast].
///
/// With reduced motion, the chart shows the final state at once.
class MarketChart extends StatefulWidget {
  const MarketChart({
    super.key,
    required this.klines,
    required this.period,
    required this.end,
    required this.color,
    required this.selection,
    required this.semanticsLabel,
  });

  static const double height = 200;

  /// Height of the time labels below the plot.
  static const double labelHeight = 24;

  /// Minimum time between two scrub haptics.
  static const Duration hapticGap = Duration(milliseconds: 80);

  final List<double> klines;
  final MarketPeriod period;

  /// Time of the last point.
  final DateTime end;

  /// Color of the line, the fill, and the scrub ring.
  final Color color;

  final ValueNotifier<MarketSelection?> selection;

  /// Summary of the chart for screen readers.
  final String semanticsLabel;

  @override
  State<MarketChart> createState() => _MarketChartState();
}

class _MarketChartState extends State<MarketChart>
    with SingleTickerProviderStateMixin {
  /// Fades the range in and out.
  late final AnimationController _rangeReveal = AnimationController(
    vsync: this,
    duration: Motion.durationFast,
  );

  /// The last range, painted while it fades out.
  MarketRange? _lastRange;

  /// Frame time of the last selection haptic. The frame clock is precise
  /// enough for [MarketChart.hapticGap] and follows the fake clock in
  /// tests.
  Duration? _lastHaptic;

  double _width = 1;

  @override
  void initState() {
    super.initState();
    widget.selection.addListener(_onSelection);
    // A range that exists before the chart shows without a fade.
    if (_selection case final MarketRange range) {
      _lastRange = range;
      _rangeReveal.value = 1;
    }
  }

  @override
  void didUpdateWidget(MarketChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      oldWidget.selection.removeListener(_onSelection);
      widget.selection.addListener(_onSelection);
      _onSelection();
    }
  }

  @override
  void dispose() {
    widget.selection.removeListener(_onSelection);
    _rangeReveal.dispose();
    super.dispose();
  }

  MarketSelection? get _selection => widget.selection.value;

  void _onSelection() {
    final selection = _selection;
    final reduced = Motion.isReduced(context);
    if (selection is MarketRange) {
      _lastRange = selection;
      reduced ? _rangeReveal.value = 1 : _rangeReveal.forward();
    } else {
      reduced ? _rangeReveal.value = 0 : _rangeReveal.reverse();
    }
  }

  int _indexAt(double dx) {
    final last = widget.klines.length - 1;
    return (dx / _width * last).round().clamp(0, last);
  }

  void _select(MarketSelection? selection) {
    final previous = _selection;
    if (selection == previous) return;
    final moved = switch ((previous, selection)) {
      (MarketPoint(index: final a), MarketPoint(index: final b)) => a != b,
      (MarketRange(), MarketRange()) => true,
      (_, MarketPoint()) => true,
      _ => false,
    };
    if (moved) _tick();
    widget.selection.value = selection;
  }

  /// Plays a selection click, at most every [MarketChart.hapticGap].
  void _tick() {
    final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final last = _lastHaptic;
    if (last == null || now - last >= MarketChart.hapticGap) {
      HapticFeedback.selectionClick();
      _lastHaptic = now;
    }
  }

  // Scrub, or move a range marker.

  void _onDragDown(DragDownDetails details) {
    if (_selection is MarketRange) return;
    _select(MarketPoint(_indexAt(details.localPosition.dx)));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final index = _indexAt(details.localPosition.dx);
    final selection = _selection;
    _select(
      selection is MarketRange
          ? selection.moveNearest(index)
          : MarketPoint(index),
    );
  }

  void _onDragEnd() {
    if (_selection is MarketPoint) _select(null);
  }

  // Range.

  void _onLongPressStart(LongPressStartDetails details) {
    final index = _indexAt(details.localPosition.dx);
    HapticFeedback.lightImpact();
    _lastHaptic = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    widget.selection.value = MarketRange(index, index);
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    final selection = _selection;
    if (selection is! MarketRange) return;
    _select(MarketRange(selection.a, _indexAt(details.localPosition.dx)));
  }

  void _onTapUp(TapUpDetails details) {
    if (_selection is MarketRange) _select(null);
  }

  Map<Type, GestureRecognizerFactory> _gestures({required bool range}) {
    void configureDrag(DragGestureRecognizer recognizer) => recognizer
      ..dragStartBehavior = DragStartBehavior.down
      ..onDown = _onDragDown
      ..onUpdate = _onDragUpdate
      ..onEnd = ((_) => _onDragEnd())
      ..onCancel = _onDragEnd;

    return {
      HorizontalDragGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
            () => HorizontalDragGestureRecognizer(debugOwner: this),
            configureDrag,
          ),
      // A vertical drag closes the sheet, except while a range is shown:
      // then the chart takes it, so a slip of the finger keeps the sheet.
      if (range)
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(debugOwner: this),
              configureDrag,
            ),
      LongPressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(debugOwner: this),
            (recognizer) => recognizer
              ..onLongPressStart = _onLongPressStart
              ..onLongPressMoveUpdate = _onLongPressMove,
          ),
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            (recognizer) => recognizer..onTapUp = _onTapUp,
          ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final klines = widget.klines;
    final color = widget.color;
    final guide = AppSurfaces.hairline(context);

    final low = klines.reduce((a, b) => a < b ? a : b);
    final high = klines.reduce((a, b) => a > b ? a : b);
    final range = high - low;
    final padding = range == 0
        ? (high.abs() * 0.01).clamp(1.0, 100.0)
        : range * 0.12;
    final minY = low - padding;
    final maxY = high + padding;

    final last = klines.length - 1;
    final labelIndices = {0, last ~/ 2, last};

    final chart = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.durationChartDraw),
      curve: Motion.curveEnter,
      builder: (context, reveal, child) => ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: reveal,
          child: child,
        ),
      ),
      child: RepaintBoundary(
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            clipData: const FlClipData.horizontal(),
            // The chart handles touches itself (see the gestures below).
            lineTouchData: const LineTouchData(enabled: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 4,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: guide, strokeWidth: 1, dashArray: const [4, 4]),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: klines.first,
                  color: context.colors.textTertiary,
                  strokeWidth: 1,
                  dashArray: const [2, 4],
                ),
              ],
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: MarketChart.labelHeight,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (value != index || !labelIndices.contains(index)) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 6,
                      fitInside: SideTitleFitInsideData.fromTitleMeta(
                        meta,
                        distanceFromEdge: 0,
                      ),
                      child: Text(
                        formatMarketTime(
                          context,
                          marketPointTime(
                            index,
                            klines.length,
                            widget.period,
                            widget.end,
                          ),
                          widget.period,
                        ),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < klines.length; i++)
                    FlSpot(i.toDouble(), klines[i]),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: color,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.22),
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: Motion.of(context, Motion.durationEmphasis),
          curve: Motion.curveMove,
        ),
      ),
    );

    return Semantics(
      label: widget.semanticsLabel,
      hint: t.wallet_asset_chart_range_hint,
      child: ExcludeSemantics(
        child: SizedBox(
          height: MarketChart.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              chart,
              LayoutBuilder(
                builder: (context, constraints) {
                  _width = constraints.maxWidth;
                  return ValueListenableBuilder<MarketSelection?>(
                    valueListenable: widget.selection,
                    builder: (context, selection, _) => RawGestureDetector(
                      behavior: HitTestBehavior.opaque,
                      gestures: _gestures(range: selection is MarketRange),
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _rangeReveal,
                          builder: (context, _) => CustomPaint(
                            painter: _SelectionPainter(
                              klines: klines,
                              minY: minY,
                              maxY: maxY,
                              point: selection is MarketPoint
                                  ? selection
                                  : null,
                              range: _lastRange,
                              rangeReveal: _rangeReveal.value,
                              lineColor: color,
                              upColor: context.colors.positiveColor,
                              downColor: context.colors.negativeColor,
                              flatColor: context.colors.textSecondary,
                              guideColor: context.colors.textSecondary,
                              ringFill: BackdropStyle.of(context).base,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the scrub point, or the range: the shaded area between the
/// markers, two vertical guides, a dashed link between the two prices, a
/// hollow ring at the start, and a filled ring at the end.
///
/// The range color follows its direction: positive up, negative down,
/// neutral flat. The markers keep different rings, so color is never the
/// only sign of which marker is which.
class _SelectionPainter extends CustomPainter {
  _SelectionPainter({
    required this.klines,
    required this.minY,
    required this.maxY,
    required this.point,
    required this.range,
    required this.rangeReveal,
    required this.lineColor,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
    required this.guideColor,
    required this.ringFill,
  });

  final List<double> klines;
  final double minY;
  final double maxY;
  final MarketPoint? point;
  final MarketRange? range;
  final double rangeReveal;
  final Color lineColor;
  final Color upColor;
  final Color downColor;
  final Color flatColor;
  final Color guideColor;
  final Color ringFill;

  static const double _ringRadius = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final length = klines.length;
    if (length < 2) return;
    final plot = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height - MarketChart.labelHeight,
    );
    Offset at(int index) => Offset(
      index / (length - 1) * plot.width,
      plot.top + (maxY - klines[index]) / (maxY - minY) * plot.height,
    );

    final range = this.range;
    if (range != null && rangeReveal > 0 && range.fits(length)) {
      final start = at(range.from);
      final end = at(range.to);
      final change = klines[range.to] - klines[range.from];
      final color = change > 0
          ? upColor
          : change < 0
          ? downColor
          : flatColor;
      final reveal = rangeReveal;

      canvas.drawRect(
        Rect.fromLTRB(start.dx, plot.top, end.dx, plot.bottom),
        Paint()..color = color.withValues(alpha: 0.12 * reveal),
      );
      final guide = Paint()
        ..color = guideColor.withValues(alpha: 0.6 * reveal)
        ..strokeWidth = 1;
      for (final x in [start.dx, end.dx]) {
        canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), guide);
      }
      _dashed(
        canvas,
        start,
        end,
        Paint()
          ..color = color.withValues(alpha: 0.8 * reveal)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      _ring(canvas, start, fill: ringFill, stroke: color, opacity: reveal);
      _ring(canvas, end, fill: color, stroke: ringFill, opacity: reveal);
      return;
    }

    final point = this.point;
    if (point != null && point.fits(length)) {
      final center = at(point.index);
      _dashed(
        canvas,
        Offset(center.dx, plot.top),
        Offset(center.dx, plot.bottom),
        Paint()
          ..color = guideColor
          ..strokeWidth = 1,
      );
      _ring(canvas, center, fill: ringFill, stroke: lineColor, opacity: 1);
    }
  }

  void _ring(
    Canvas canvas,
    Offset center, {
    required Color fill,
    required Color stroke,
    required double opacity,
  }) {
    canvas.drawCircle(
      center,
      _ringRadius,
      Paint()..color = fill.withValues(alpha: fill.a * opacity),
    );
    canvas.drawCircle(
      center,
      _ringRadius,
      Paint()
        ..color = stroke.withValues(alpha: stroke.a * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  /// Draws a 4 on, 4 off dashed line from [from] to [to].
  static void _dashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 4.0;
    final delta = to - from;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    for (var d = 0.0; d < distance; d += dash * 2) {
      canvas.drawLine(
        from + direction * d,
        from + direction * math.min(d + dash, distance),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) =>
      oldDelegate.point != point ||
      oldDelegate.range != range ||
      oldDelegate.rangeReveal != rangeReveal ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.ringFill != ringFill ||
      oldDelegate.minY != minY ||
      oldDelegate.maxY != maxY ||
      !identical(oldDelegate.klines, klines);
}

/// A skeleton in the shape of a [MarketChart].
class MarketChartSkeleton extends StatelessWidget {
  const MarketChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: SkeletonBox(
        width: double.infinity,
        height: MarketChart.height,
        radius: 16,
      ),
    );
  }
}

/// The chart area while its first data loads, without a skeleton: the empty
/// plot with the loading pill of [MarketChartUpdating].
class MarketChartLoading extends StatelessWidget {
  const MarketChartLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      height: MarketChart.height,
      child: Center(child: _LoadingPill()),
    );
  }
}

/// Switches the chart area between its states: a [MarketChartSkeleton] or
/// a [MarketChartLoading], a [MarketChart], or a [MarketChartUnavailable].
/// Give each state its own key.
///
/// The old state fades out before the new one fades in, over
/// [Motion.durationBase]: the chart has no fill of its own, so in a
/// cross-fade the gray skeleton would show through it. With reduced
/// motion, the state changes at once.
class MarketChartSwitcher extends StatelessWidget {
  const MarketChartSwitcher({super.key, required this.child});

  /// Share of the switch in which the old state fades out. The new state
  /// fades in over the rest.
  static const double handOver = 0.35;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.durationBase),
      // The new state plays forward and the old one in reverse, so each
      // curve covers its own part of the switch.
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(handOver, 1, curve: Motion.curveEnter),
          reverseCurve: const Interval(
            1 - handOver,
            1,
            curve: Motion.curveExit,
          ),
        ),
        child: child,
      ),
      child: child,
    );
  }
}

/// Shows that [child], a [MarketChart], is loading the data of a new
/// period.
///
/// While [updating] is true, the chart stays in place, dims, and ignores
/// touches, and a glass pill over its center says that it is loading. The
/// dimming and the pill fade in and out over [Motion.durationFast]. With
/// reduced motion, they change at once and the pill shows no spinner.
class MarketChartUpdating extends StatelessWidget {
  const MarketChartUpdating({
    super.key,
    required this.updating,
    required this.child,
  });

  /// Opacity of the chart while it loads.
  static const double dimmedOpacity = 0.4;

  final bool updating;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.durationFast);
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          ignoring: updating,
          child: AnimatedOpacity(
            opacity: updating ? dimmedOpacity : 1,
            duration: duration,
            curve: Motion.curveMove,
            child: child,
          ),
        ),
        // The switcher removes the pill when it is hidden, so the spinner
        // does not tick behind a zero opacity.
        AnimatedSwitcher(
          duration: duration,
          switchInCurve: Motion.curveEnter,
          switchOutCurve: Motion.curveExit,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: updating
              ? const _LoadingPill(key: ValueKey('loading'))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A small glass pill with a spinner and "Loading".
class _LoadingPill extends StatelessWidget {
  const _LoadingPill({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = context.colors.textSecondary;
    return Semantics(
      liveRegion: true,
      child: LiquidGlass(
        blurBackdrop: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!Motion.isReduced(context)) ...[
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                t.common_loading,
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The place of a [MarketChart] when the history did not load. [onRetry]
/// shows a retry button.
class MarketChartUnavailable extends StatelessWidget {
  const MarketChartUnavailable({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SizedBox(
      height: MarketChart.height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixIcon(
              PixIcons.info,
              size: 24,
              color: context.colors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              t.wallet_asset_chart_load_error,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            if (onRetry case final onRetry?) ...[
              const SizedBox(height: 4),
              TextButton(onPressed: onRetry, child: Text(t.common_retry)),
            ],
          ],
        ),
      ),
    );
  }
}
