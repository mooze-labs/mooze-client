import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One part of an [AllocationBar].
@immutable
class AllocationSegment {
  const AllocationSegment({required this.share, required this.color});

  /// Fraction of the total, from 0 to 1.
  final double share;
  final Color color;
}

/// Returns the color of the holding with [rank] in the allocation.
///
/// Rank 0 is the largest holding. It uses the brand color. The other
/// holdings use neutral tones that get lighter by rank, so the chart has
/// one accent hue.
Color allocationColor(BuildContext context, int rank) {
  if (rank == 0) return context.colors.primaryColor;
  const alphas = [0.6, 0.36, 0.2, 0.12];
  final alpha = alphas[(rank - 1).clamp(0, alphas.length - 1)];
  return context.colors.textPrimary.withValues(alpha: alpha);
}

/// A thin bar that shows the share of each holding in the total.
///
/// A share above 0 gets at least [minSegment] of width, so a small holding
/// stays visible next to a large one.
///
/// Motion:
/// - First show per app session: the bar draws from left to right over
///   [Motion.durationChartDraw].
/// - New shares: each segment changes its width over
///   [Motion.durationEmphasis].
///
/// With reduced motion, the bar shows the final state at once. The legend
/// carries the values for screen readers, so the bar has no semantics.
class AllocationBar extends StatefulWidget {
  const AllocationBar({super.key, required this.segments});

  final List<AllocationSegment> segments;

  static const double height = 10;
  static const double gap = 3;

  /// Minimum width of a segment with a share above 0.
  static const double minSegment = 6;

  /// Returns the segment widths for [usable] width.
  ///
  /// Shares that would be narrower than [minSegment] get [minSegment]. The
  /// other segments share the rest by their shares.
  static List<double> widthsFor(List<double> shares, double usable) {
    final small = [for (final share in shares) share * usable < minSegment];
    final reserved = minSegment * small.where((isSmall) => isSmall).length;
    final largeTotal = [
      for (var i = 0; i < shares.length; i++)
        if (!small[i]) shares[i],
    ].fold<double>(0, (sum, share) => sum + share);
    final rest = (usable - reserved).clamp(0.0, double.infinity);
    return [
      for (var i = 0; i < shares.length; i++)
        small[i]
            ? minSegment
            : (largeTotal == 0 ? 0 : rest * shares[i] / largeTotal),
    ];
  }

  static bool _revealed = false;

  /// Lets the next mount draw the bar again.
  @visibleForTesting
  static void resetSession() => _revealed = false;

  @override
  State<AllocationBar> createState() => _AllocationBarState();
}

class _AllocationBarState extends State<AllocationBar> {
  /// Read once, so a rebuild does not start the reveal again.
  late final bool _reveal;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reveal = !AllocationBar._revealed && !Motion.isReduced(context);
    AllocationBar._revealed = true;
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.segments;
    final bar = LayoutBuilder(
      builder: (context, constraints) {
        final gaps = AllocationBar.gap * (segments.length - 1);
        final usable = (constraints.maxWidth - gaps).clamp(
          0.0,
          double.infinity,
        );
        final widths = AllocationBar.widthsFor([
          for (final segment in segments) segment.share,
        ], usable);
        return Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: AllocationBar.gap),
              AnimatedContainer(
                duration: Motion.of(context, Motion.durationEmphasis),
                curve: Motion.curveMove,
                width: widths[i],
                height: AllocationBar.height,
                decoration: BoxDecoration(
                  color: segments[i].color,
                  borderRadius: BorderRadius.circular(AllocationBar.height / 2),
                ),
              ),
            ],
          ],
        );
      },
    );

    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: _reveal ? 0 : 1, end: 1),
        duration: _reveal ? Motion.durationChartDraw : Duration.zero,
        curve: Motion.curveEnter,
        builder: (context, reveal, child) => ClipRect(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: reveal,
            child: child,
          ),
        ),
        child: bar,
      ),
    );
  }
}

/// One entry of an [AllocationLegend].
@immutable
class AllocationEntry {
  const AllocationEntry({
    required this.label,
    required this.share,
    required this.color,
  });

  /// Short name, for example the ticker.
  final String label;

  /// Fraction of the total, from 0 to 1.
  final double share;
  final Color color;
}

/// The key of an [AllocationBar]: a dot, a label, and a percentage per
/// entry, in two columns. The percentages are right-aligned in each column,
/// so they line up.
///
/// When [isHidden] is true, the percentages cross-fade to a mask over
/// [Motion.durationFast]. With reduced motion, they change at once.
class AllocationLegend extends StatelessWidget {
  const AllocationLegend({
    super.key,
    required this.entries,
    required this.isHidden,
  });

  final List<AllocationEntry> entries;
  final bool isHidden;

  static const double _columnGap = 24;
  static const double _rowGap = 8;
  static const String _mask = '•••';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final percent = NumberFormat(
      '0.0',
      Localizations.localeOf(context).toString(),
    );
    final labelStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - _columnGap) / 2;
        return Wrap(
          spacing: _columnGap,
          runSpacing: _rowGap,
          children: [
            for (final entry in entries)
              SizedBox(
                width: columnWidth,
                child: MergeSemantics(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: entry.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.label,
                          style: labelStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: Motion.of(context, Motion.durationFast),
                        switchInCurve: Motion.curveMove,
                        switchOutCurve: Motion.curveMove,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: AlignmentDirectional.centerEnd,
                          children: [...previous, if (current != null) current],
                        ),
                        child: isHidden
                            ? Semantics(
                                key: const ValueKey('mask'),
                                label: t.wallet_amount_hidden,
                                excludeSemantics: true,
                                child: Text(_mask, style: valueStyle),
                              )
                            : Text(
                                '${percent.format(entry.share * 100)}%',
                                key: const ValueKey('value'),
                                style: valueStyle,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
