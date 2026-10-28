import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/data_refresh_trigger.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/asset_detail/asset_detail_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_icon_hero.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/percentage_variation_display.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/animated_amount.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The favorite assets as rows in one Liquid Glass panel, separated by inset
/// hairlines.
class AssetRowList extends ConsumerWidget {
  const AssetRowList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the refresh trigger to re-render without loading state.
    ref.watch(dataRefreshTriggerProvider);

    final favoriteAssets = ref.watch(favoriteAssetsProvider);

    if (favoriteAssets.isEmpty) return const SizedBox.shrink();

    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < favoriteAssets.length; i++) ...[
            if (i > 0) const PanelDivider(indent: AssetRowView.textInset),
            AssetRow(asset: favoriteAssets[i]),
          ],
        ],
      ),
    );
  }
}

/// One asset: icon, name, ticker, 24 h sparkline, price, and change.
///
/// A tap opens the asset detail. The icon flies to the detail screen as a
/// Hero.
class AssetRow extends ConsumerWidget {
  const AssetRow({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedPriceHistory = ref.watch(
      cachedAssetPriceHistoryProvider(asset),
    );

    final Widget trailing;
    if (cachedPriceHistory == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(assetPriceHistoryCacheProvider.notifier)
            .fetchAssetPriceHistory(asset);
      });
      trailing = const _LoadingTrailing(key: ValueKey('loading'));
    } else {
      trailing = cachedPriceHistory.fold(
        (err) {
          if (kDebugMode) debugPrint("[KLINES] $err");
          return const _ErrorTrailing(key: ValueKey('error'));
        },
        (klines) => _PriceTrailing(
          key: const ValueKey('data'),
          asset: asset,
          klines: klines,
        ),
      );
    }

    return AssetRowView(
      asset: asset,
      trailing: trailing,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetDetailScreen(asset: asset),
          ),
        );
      },
    );
  }
}

/// The layout of an asset row. The icon and the names stay in place while
/// [trailing] cross-fades from skeleton to content.
///
/// [trailing] gets a box of fixed width. It must fit that box, for example
/// with a [FittedBox] that scales the price down.
class AssetRowView extends StatelessWidget {
  const AssetRowView({
    super.key,
    required this.asset,
    required this.trailing,
    required this.onTap,
  });

  static const double iconSize = 40;

  /// Space between the panel edge and the row content.
  static const double horizontalPadding = 16;

  /// Distance from the panel edge to the row text. Dividers start here.
  static const double textInset = horizontalPadding + iconSize + 12;

  /// Share of the free row width for [trailing].
  ///
  /// The trailing part has a fixed width, so the sparklines of all rows
  /// line up. A wider price scales down inside it.
  static const double trailingShare = 0.7;

  final Asset asset;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final freeWidth = constraints.maxWidth - iconSize - 24;
              return Row(
                children: [
                  AssetIconHero(asset: asset, size: iconSize),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.displayName,
                          style: textTheme.bodyLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          asset.ticker,
                          style: textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: freeWidth * trailingShare,
                    child: AnimatedSwitcher(
                      duration: Motion.of(context, Motion.durationBase),
                      switchInCurve: Motion.curveMove,
                      switchOutCurve: Motion.curveMove,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: AlignmentDirectional.centerEnd,
                        children: [...previous, if (current != null) current],
                      ),
                      child: trailing,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Returns true when the row has room for a sparkline.
///
/// Large text scales and narrow screens drop the sparkline, so that the
/// price keeps its full size.
bool _showSparkline(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  final width = MediaQuery.sizeOf(context).width;
  return textScale <= 1.3 && width >= 360;
}

class _PriceTrailing extends ConsumerWidget {
  const _PriceTrailing({super.key, required this.asset, required this.klines});

  final Asset asset;
  final List<double> klines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotPrice = ref.watch(
      priceQuotesProvider.select((s) => s.priceFor(asset)),
    );
    final icon = ref.watch(currencyControllerProvider.notifier).icon;
    final numberFormat = NumberFormat(
      '#,##0.00',
      Localizations.localeOf(context).toString(),
    );

    final first = klines.isEmpty ? 0.0 : klines.first;
    final last = klines.isEmpty ? 0.0 : klines.last;
    final percentage = first == 0 ? 0.0 : ((last - first) / first) * 100;
    final assetValue = spotPrice ?? last;

    final lineColor = percentage > 0
        ? context.colors.positiveColor
        : percentage < 0
        ? context.colors.negativeColor
        : context.colors.textSecondary;

    return Row(
      children: [
        if (_showSparkline(context) && klines.length > 1) ...[
          Sparkline(values: klines, color: lineColor, revealId: asset),
          const SizedBox(width: 16),
        ],
        _FitEnd(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedAmount(
                text: "$icon ${numberFormat.format(assetValue)}",
                value: assetValue,
                alignment: AlignmentDirectional.centerEnd,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ChangeChip(percentage: percentage),
            ],
          ),
        ),
      ],
    );
  }
}

/// Puts [child] at the end of the free space and scales it down when it
/// does not fit, so a price never wraps or overflows.
class _FitEnd extends StatelessWidget {
  const _FitEnd({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: child,
        ),
      ),
    );
  }
}

class _ErrorTrailing extends StatelessWidget {
  const _ErrorTrailing({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (_showSparkline(context)) ...[
          SizedBox(
            width: Sparkline.width,
            height: Sparkline.height,
            child: Center(
              child: Container(height: 1.5, color: context.colorScheme.outline),
            ),
          ),
          const SizedBox(width: 16),
        ],
        _FitEnd(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'N/A',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const UnavailableChangeChip(),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingTrailing extends StatelessWidget {
  const _LoadingTrailing({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Row(
        children: [
          if (_showSparkline(context)) ...[
            const SkeletonBox(
              width: Sparkline.width,
              height: Sparkline.height,
              radius: 6,
            ),
            const SizedBox(width: 16),
          ],
          const _FitEnd(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBox(width: 88, height: 18),
                SizedBox(height: 6),
                SkeletonBox(width: 56, height: 20, radius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small line chart of [values] with a soft area fill below the line.
///
/// Motion:
/// - First show per app session and [revealId]: the line draws from left to
///   right over [Motion.durationEmphasis].
/// - New [values]: the line morphs to the new shape over
///   [Motion.durationEmphasis].
///
/// With reduced motion, the final line shows at once.
class Sparkline extends StatefulWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.revealId,
  });

  static const double width = 64;
  static const double height = 28;

  final List<double> values;
  final Color color;

  /// Identifies the series for the reveal. Null disables the reveal.
  final Object? revealId;

  @override
  State<Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<Sparkline> with TickerProviderStateMixin {
  /// Series that already showed their reveal in this app session.
  static final Set<Object> _revealed = {};

  /// Number of points after resampling. Equal lengths make the morph
  /// possible between series of different lengths.
  static const int _samples = 32;

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: Motion.durationEmphasis,
    value: 1,
  );
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: Motion.durationEmphasis,
    value: 1,
  );
  late final CurvedAnimation _revealCurve = CurvedAnimation(
    parent: _reveal,
    curve: Motion.curveEnter,
  );
  late final CurvedAnimation _morphCurve = CurvedAnimation(
    parent: _morph,
    curve: Motion.curveMove,
  );

  late List<double> _from;
  late List<double> _to;
  late Color _fromColor;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _from = _normalize(widget.values);
    _to = _from;
    _fromColor = widget.color;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final id = widget.revealId;
    if (id == null) return;
    final firstShow = _revealed.add(id);
    if (firstShow && !Motion.isReduced(context)) {
      _reveal.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(Sparkline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final valuesChanged = !listEquals(oldWidget.values, widget.values);
    final colorChanged = oldWidget.color != widget.color;
    if (!valuesChanged && !colorChanged) return;

    final t = _morphCurve.value;
    _from = _lerpList(_from, _to, t);
    _fromColor = Color.lerp(_fromColor, oldWidget.color, t)!;
    _to = _normalize(widget.values);
    if (Motion.isReduced(context)) {
      _morph.value = 1;
    } else {
      _morph.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _revealCurve.dispose();
    _morphCurve.dispose();
    _reveal.dispose();
    _morph.dispose();
    super.dispose();
  }

  /// Resamples [values] to [_samples] points and scales them to 0..1.
  static List<double> _normalize(List<double> values) {
    if (values.isEmpty) return List.filled(_samples, 0.5);
    final resampled = List<double>.generate(_samples, (i) {
      if (values.length == 1) return values.first;
      final position = i * (values.length - 1) / (_samples - 1);
      final lower = position.floor();
      final upper = position.ceil().clamp(0, values.length - 1);
      final fraction = position - lower;
      return values[lower] + (values[upper] - values[lower]) * fraction;
    });
    final minValue = resampled.reduce((a, b) => a < b ? a : b);
    final maxValue = resampled.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    return [
      for (final v in resampled) range == 0 ? 0.5 : (v - minValue) / range,
    ];
  }

  static List<double> _lerpList(List<double> a, List<double> b, double t) => [
    for (var i = 0; i < b.length; i++) a[i] + (b[i] - a[i]) * t,
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: Sparkline.width,
          height: Sparkline.height,
          child: AnimatedBuilder(
            animation: Listenable.merge([_reveal, _morph]),
            builder: (context, _) {
              final t = _morphCurve.value;
              return CustomPaint(
                painter: _SparklinePainter(
                  points: _lerpList(_from, _to, t),
                  color: Color.lerp(_fromColor, widget.color, t)!,
                  reveal: _revealCurve.value,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.points,
    required this.color,
    required this.reveal,
  });

  /// Normalized values in 0..1. 1 is the top.
  final List<double> points;
  final Color color;

  /// Visible fraction of the line, from the left.
  final double reveal;

  static const double _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || reveal <= 0) return;

    // Keep the stroke inside the box at the minimum and the maximum.
    const inset = _strokeWidth;
    final height = size.height - inset * 2;
    final offsets = [
      for (var i = 0; i < points.length; i++)
        Offset(
          i / (points.length - 1) * size.width,
          inset + height * (1 - points[i]),
        ),
    ];

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    path.lineTo(offsets.last.dx, offsets.last.dy);

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        -inset,
        -inset,
        size.width * reveal + inset * 2,
        size.height + inset * 2,
      ),
    );
    // Soft area below the line: the line color fades to transparent, as in
    // the hero charts of the references (chartAreaFill).
    final area = Path.from(path)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = _strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.reveal != reveal ||
      oldDelegate.color != color ||
      !listEquals(oldDelegate.points, points);
}
