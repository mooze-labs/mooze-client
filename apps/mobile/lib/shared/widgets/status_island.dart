import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One glass island for the app statuses, like a Dynamic Island that shows
/// several activities: the offline state, the wallet loading, and a failed
/// sync.
///
/// The parts sit in order of priority, from the start to the end: offline,
/// loading, sync error. The highest part present leads: it is a pill with
/// its label, at the end of the island. The others contract to dots before
/// it, and short liquid bridges join them. For example:
///
/// - Offline only: a pill with a cloud and "Offline".
/// - Offline and loading: an offline dot, then the loading pill.
/// - Offline and sync error: an offline dot, then the error pill.
/// - All three: there is no room for a label, so all three are dots.
/// - None: the island shrinks away and gives its space back.
///
/// Every change morphs the same shape. A new part grows out of a bridge as
/// a dot and stretches to show its label. A part that leaves shrinks back
/// into the bridge, and the new lead takes its full size. The morph runs on
/// springs that keep their speed, so a change in the middle of a morph
/// stays smooth. With reduced motion, the island takes the new shape at
/// once.
///
/// A pull-to-refresh can bring the loading part in by hand: with [pull],
/// the part follows the finger, and its icon winds with it. When the pull
/// ends, the island springs to its state.
///
/// [offline], [loading], [syncError], and [pull] drive the island. It has
/// no business logic.
class StatusIsland extends StatefulWidget {
  const StatusIsland({
    super.key,
    required this.offline,
    required this.loading,
    required this.loadingLabel,
    this.loadingSemanticsLabel,
    this.syncError = false,
    this.syncErrorLabel = '',
    this.syncErrorSemanticsLabel,
    this.offlineLabel = 'Offline',
    this.onOfflineTap,
    this.onSyncErrorTap,
    this.alignment = Alignment.center,
    this.pull = 0,
  });

  /// The app shows saved prices because it is offline.
  final bool offline;

  /// The wallet loads its transactions.
  final bool loading;

  /// The sync of the Mooze services failed.
  final bool syncError;

  /// How far a pull-to-refresh has gone, from 0 to 1, as
  /// `PullRefreshController.progress` reports it. While [loading] is false,
  /// the loading part follows the pull: it grows in as a dot and opens to
  /// its pill at 1. When the pull ends, the island springs to its state:
  /// to the loading part if a refresh starts, back if the pull stopped
  /// short.
  final double pull;

  /// The short label of the loading part, such as "Sync".
  final String loadingLabel;

  /// What screen readers say for the loading part. Defaults to
  /// [loadingLabel].
  final String? loadingSemanticsLabel;

  /// The short label of the sync error part, such as "Erro".
  final String syncErrorLabel;

  /// What screen readers say for the sync error part. Defaults to
  /// [syncErrorLabel].
  final String? syncErrorSemanticsLabel;

  final String offlineLabel;

  /// Opens the details of the offline state. The dot answers a tap too.
  final VoidCallback? onOfflineTap;

  /// Opens the details of the failed sync, with a retry.
  final VoidCallback? onSyncErrorTap;

  /// Where the island sits in the room it gets. In a corner, the end
  /// alignment keeps the island against the edge, and it grows toward the
  /// center. Where the width is unbounded, as in app bar actions, the island
  /// takes only its own width.
  final AlignmentGeometry alignment;

  /// Keys of the parts, for tests.
  static const offlineKey = ValueKey('status_island.offline');
  static const loadingKey = ValueKey('status_island.loading');
  static const syncErrorKey = ValueKey('status_island.sync_error');

  @override
  State<StatusIsland> createState() => _StatusIslandState();
}

class _StatusIslandState extends State<StatusIsland>
    with TickerProviderStateMixin {
  /// The index of the loading part.
  static const _loading = 1;

  /// Which parts show, in order of priority.
  static List<bool> _shownOf(StatusIsland island) => [
    island.offline,
    island.loading,
    island.syncError,
  ];

  /// How far each part opens: the lead opens to show its label, when it
  /// shares the island with one other part at most. The others are dots.
  static List<double> _openOf(List<bool> shown) {
    final lead = shown.lastIndexOf(true);
    final count = shown.where((part) => part).length;
    return [
      for (var i = 0; i < shown.length; i++)
        i == lead && count <= 2 ? 1.0 : 0.0,
    ];
  }

  // Each value goes from 0 to 1. Springs may carry them a little past.
  // How much of each part shows.
  late final List<AnimationController> _presence = [
    for (final shown in _shownOf(widget))
      AnimationController.unbounded(vsync: this, value: shown ? 1 : 0),
  ];

  // How far each part opens: 0 is the dot, 1 is the full pill.
  late final List<AnimationController> _open = [
    for (final open in _openOf(_shownOf(widget)))
      AnimationController.unbounded(vsync: this, value: open),
  ];

  late final Listenable _morph = Listenable.merge([..._presence, ..._open]);

  @override
  void initState() {
    super.initState();
    if (_pulled(widget)) _follow(_shownOf(widget), widget.pull);
  }

  @override
  void didUpdateWidget(StatusIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shown = _shownOf(widget);
    final changed = !listEquals(shown, _shownOf(oldWidget));
    if (_pulled(widget)) {
      // The other parts still spring to their state.
      if (changed) {
        for (var i = 0; i < shown.length; i++) {
          if (i != _loading) _morphTo(_presence[i], shown[i] ? 1 : 0);
        }
      }
      _follow(shown, widget.pull);
      return;
    }
    if (!changed && !_pulled(oldWidget)) return;
    final open = _openOf(shown);
    for (var i = 0; i < shown.length; i++) {
      _morphTo(_presence[i], shown[i] ? 1 : 0);
      _morphTo(_open[i], open[i]);
    }
  }

  /// The loading part follows a pull, rather than [StatusIsland.loading].
  static bool _pulled(StatusIsland island) =>
      island.pull > 0 && !island.loading;

  /// Puts the loading part [pull] of the way in, with no spring: the parts
  /// take the shape between [shown] and [shown] with the loading.
  void _follow(List<bool> shown, double pull) {
    final from = _openOf(shown);
    final to = _openOf([
      for (var i = 0; i < shown.length; i++) i == _loading || shown[i],
    ]);
    _presence[_loading].value = pull;
    for (var i = 0; i < shown.length; i++) {
      if (from[i] != to[i]) _open[i].value = lerpDouble(from[i], to[i], pull)!;
    }
  }

  void _morphTo(AnimationController controller, double target) {
    if (Motion.isReduced(context)) {
      controller.value = target;
      return;
    }
    // The spring starts from the current value and speed, so a morph that
    // turns back midway does not jump.
    controller.animateWith(
      SpringSimulation(
        Motion.springMorph,
        controller.value,
        target,
        controller.velocity,
        snapToEnd: true,
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [..._presence, ..._open]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strongStyle = context.textTheme.labelSmall?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final mutedStyle = context.textTheme.labelSmall?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w500,
    );
    final warning = context.appColors.warning;
    final error = context.colorScheme.error;
    final muted = context.colors.textSecondary;
    final specs = [
      _PartSpec(
        key: StatusIsland.offlineKey,
        iconSize: 16,
        icon: (size) => PixIcon(PixIcons.offline, size: size, color: warning),
        label: widget.offlineLabel,
        style: strongStyle,
        semanticsLabel: widget.offlineLabel,
        onTap: widget.onOfflineTap,
      ),
      _PartSpec(
        key: StatusIsland.loadingKey,
        iconSize: 14,
        // Half a turn as the part comes in. The icon unwinds as it leaves.
        icon: (size) => _SyncIcon(
          size: size,
          color: muted,
          spinning: widget.loading,
          wind: _presence[_loading].value / 2,
        ),
        label: widget.loadingLabel,
        style: mutedStyle,
        semanticsLabel: widget.loadingSemanticsLabel ?? widget.loadingLabel,
        announce: true,
      ),
      _PartSpec(
        key: StatusIsland.syncErrorKey,
        iconSize: 14,
        icon: (size) => PixIcon(PixIcons.error, size: size, color: error),
        label: widget.syncErrorLabel,
        style: strongStyle,
        semanticsLabel: widget.syncErrorSemanticsLabel ?? widget.syncErrorLabel,
        onTap: widget.onSyncErrorTap,
        announce: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _IslandMetrics.of(
          context,
          specs: specs,
          maxWidth: constraints.maxWidth,
        );
        return AnimatedBuilder(
          animation: _morph,
          builder: (context, _) {
            final shape = metrics.shapeAt(
              presence: [for (final c in _presence) c.value],
              open: [for (final c in _open) c.value],
            );
            return Align(
              alignment: widget.alignment,
              child: SizedBox.fromSize(
                size: shape.size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _IslandPainter(
                          shape: shape,
                          glass: GlassStyle.of(context),
                        ),
                      ),
                    ),
                    for (var i = 0; i < specs.length; i++)
                      if (shape.parts[i].height > 0) ...[
                        _Part(
                          key: specs[i].key,
                          rect: shape.parts[i],
                          open: shape.openness[i],
                          iconExtent: specs[i].iconSize * shape.scales[i],
                          icon: specs[i].icon(
                            specs[i].iconSize * shape.scales[i],
                          ),
                          label: Text(
                            specs[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: specs[i].style,
                          ),
                          labelWidth: metrics.labelWidths[i],
                        ),
                        // The semantics and the tap target span the row
                        // height, so a dot is easy to hit too.
                        Positioned(
                          left: shape.parts[i].left,
                          width: shape.parts[i].width,
                          top: 0,
                          bottom: 0,
                          child: Semantics(
                            button: specs[i].onTap != null,
                            // Screen readers announce the part when it
                            // appears.
                            liveRegion: specs[i].announce,
                            label: specs[i].semanticsLabel,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: specs[i].onTap,
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// What one part of the island shows and does.
class _PartSpec {
  const _PartSpec({
    required this.key,
    required this.iconSize,
    required this.icon,
    required this.label,
    required this.style,
    required this.semanticsLabel,
    this.onTap,
    this.announce = false,
  });

  final Key key;
  final double iconSize;

  /// Builds the icon at a size, which shrinks with a part that grows or
  /// leaves.
  final Widget Function(double size) icon;

  final String label;
  final TextStyle? style;
  final String semanticsLabel;
  final VoidCallback? onTap;

  /// Screen readers announce the part when it appears.
  final bool announce;
}

/// The sizes of the island that do not change during a morph.
class _IslandMetrics {
  _IslandMetrics._({
    required this.maxWidth,
    required this.pillHeight,
    required this.fullWidths,
    required this.labelWidths,
  });

  /// Space around the content of a pill, as in the glass pills of the app.
  static const double padLeft = 10;
  static const double padRight = 12;
  static const double padVertical = 6;
  static const double iconGap = 6;

  /// Height of the row that holds the island. It is also the height of the
  /// tap targets.
  static const double rowHeight = 48;

  /// Length and waist of a bridge between two parts.
  static const double bridgeLength = 8;
  static const double bridgeWaist = 6;

  /// The room of the island. It may be infinite, as in app bar actions.
  final double maxWidth;

  final double pillHeight;

  /// Width of each part as an open pill.
  final List<double> fullWidths;

  final List<double> labelWidths;

  factory _IslandMetrics.of(
    BuildContext context, {
    required List<_PartSpec> specs,
    required double maxWidth,
  }) {
    Size measure(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final texts = [for (final spec in specs) measure(spec.label, spec.style)];
    final pillHeight =
        [
          for (var i = 0; i < specs.length; i++)
            math.max(specs[i].iconSize, texts[i].height),
        ].reduce(math.max) +
        padVertical * 2;

    // A lead shares the island with one dot of a lower part at most, so a
    // long label leaves room for that dot and its bridge, and ends in an
    // ellipsis. The first part has no lower part: it leads only alone.
    final fullWidths = <double>[];
    final labelWidths = <double>[];
    for (var i = 0; i < specs.length; i++) {
      final chrome = padLeft + specs[i].iconSize + iconGap + padRight;
      final room = i == 0 ? maxWidth : maxWidth - pillHeight - bridgeLength;
      final width = math.max(
        pillHeight,
        math.min(chrome + texts[i].width, room),
      );
      fullWidths.add(width);
      labelWidths.add(math.max(0, width - chrome));
    }
    return _IslandMetrics._(
      maxWidth: maxWidth,
      pillHeight: pillHeight,
      fullWidths: fullWidths,
      labelWidths: labelWidths,
    );
  }

  /// Returns the shape of the island for the morph values of each part.
  _IslandShape shapeAt({
    required List<double> presence,
    required List<double> open,
  }) {
    final height = rowHeight * presence.reduce(math.max).clamp(0.0, 1.0);
    final center = height / 2;
    final sizes = [
      for (var i = 0; i < presence.length; i++)
        _part(presence[i], lerpDouble(pillHeight, fullWidths[i], open[i])!),
    ];
    // The most of any part before each one. A bridge opens as a part
    // arrives after another, and closes as either leaves.
    final gaps = <double>[];
    var before = 0.0;
    for (final shown in presence) {
      gaps.add(bridgeLength * math.min(shown, before).clamp(0.0, 1.0));
      before = math.max(before, shown);
    }
    _fit(sizes, gaps);

    final parts = <Rect>[];
    final openness = <double>[];
    final scales = <double>[];
    var x = 0.0;
    for (var i = 0; i < sizes.length; i++) {
      final size = sizes[i];
      x += gaps[i];
      final rect = Rect.fromLTWH(
        x,
        center - size.height / 2,
        size.width,
        size.height,
      );
      parts.add(rect);
      openness.add(_openness(rect, fullWidths[i]));
      scales.add(size.height / pillHeight);
      x += size.width;
    }
    return _IslandShape(
      size: Size(x, height),
      parts: parts,
      openness: openness,
      scales: scales,
    );
  }

  /// Keeps the island in [maxWidth] during a morph. While a pill closes
  /// and a new part grows, both can take room at once. The open parts then
  /// give up width, each in proportion to how far it is open, down to a
  /// dot at most.
  void _fit(List<Size> sizes, List<double> gaps) {
    final total =
        sizes.fold(0.0, (sum, size) => sum + size.width) +
        gaps.fold(0.0, (sum, gap) => sum + gap);
    final excess = total - maxWidth;
    if (excess <= 0) return;
    final slack = [for (final size in sizes) size.width - size.height];
    final totalSlack = slack.fold(0.0, (sum, part) => sum + part);
    if (totalSlack <= 0) return;
    final cut = math.min(excess, totalSlack);
    for (var i = 0; i < sizes.length; i++) {
      sizes[i] = Size(
        sizes[i].width - cut * slack[i] / totalSlack,
        sizes[i].height,
      );
    }
  }

  /// The size of a part at [presence]. It first grows as a dot, then
  /// stretches to [fullWidth].
  Size _part(double presence, double fullWidth) {
    if (presence <= 0) return Size.zero;
    final grow = Curves.easeOut.transform(
      _progress(presence, 0, 0.5).clamp(0.0, 1.0),
    );
    final height = pillHeight * grow;
    // Past 1, the spring stretches the pill a little, as elastic glass.
    final stretch = presence >= 1 ? presence : _progress(presence, 0.35, 1);
    final width = math.max(height, lerpDouble(height, fullWidth, stretch)!);
    return Size(width, height);
  }

  /// How far [rect] has opened toward [fullWidth]: 0 is a dot, 1 shows the
  /// whole label.
  double _openness(Rect rect, double fullWidth) {
    final room = fullWidth - pillHeight;
    if (room <= 0) return 0;
    return ((rect.width - rect.height) / room).clamp(0.0, 1.0);
  }

  static double _progress(double value, double begin, double end) =>
      ((value - begin) / (end - begin)).clamp(0.0, 1.0);
}

/// The shape of the island at one moment of a morph.
@immutable
class _IslandShape {
  const _IslandShape({
    required this.size,
    required this.parts,
    required this.openness,
    required this.scales,
  });

  final Size size;

  /// The rectangle of each part. A part that does not show is empty.
  final List<Rect> parts;

  /// How far each part has opened: 0 is a dot, 1 shows the label.
  final List<double> openness;

  /// Height of each part, as a share of the pill height.
  final List<double> scales;

  @override
  bool operator ==(Object other) =>
      other is _IslandShape &&
      other.size == size &&
      listEquals(other.parts, parts);

  @override
  int get hashCode => Object.hash(size, Object.hashAll(parts));
}

/// One part of the island: its icon, and its label that the part reveals
/// as it opens. When the part is a dot, the icon sits in its center.
class _Part extends StatelessWidget {
  const _Part({
    super.key,
    required this.rect,
    required this.open,
    required this.icon,
    required this.iconExtent,
    required this.label,
    required this.labelWidth,
  });

  final Rect rect;
  final double open;
  final Widget icon;

  /// The size of [icon] at this moment of the morph.
  final double iconExtent;

  final Widget label;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    // The icon keeps its place at the start of the pill, and the label
    // comes out beside it. Only a dot centers its icon.
    final iconLeft = math.min(
      (rect.width - iconExtent) / 2,
      _IslandMetrics.padLeft,
    );
    return Positioned.fromRect(
      rect: rect,
      // The island gives the semantics of each part over the row height.
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(rect.height / 2),
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Padding(
              padding: EdgeInsets.only(left: math.max(0, iconLeft)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: _IslandMetrics.iconGap),
                  // The label comes in as the part opens, and goes before
                  // it closes.
                  Opacity(
                    opacity: Curves.easeIn.transform(
                      _IslandMetrics._progress(open, 0.45, 1),
                    ),
                    child: SizedBox(width: labelWidth, child: label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the island as one Liquid Glass shape: the parts and the bridges
/// between them form a single outline.
///
/// It paints the layers of a `LiquidGlass` without backdrop blur, in the
/// same order, on that outline: the control shadow, the tints, the sheen,
/// the glow inside the edge, and the rim.
class _IslandPainter extends CustomPainter {
  _IslandPainter({required this.shape, required this.glass});

  final _IslandShape shape;
  final GlassStyle glass;

  Path _outline() {
    final shown = [
      for (final rect in shape.parts)
        if (rect.height > 0) rect,
    ];
    var outline = Path();
    for (final rect in shown) {
      outline.addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      );
    }
    for (var i = 1; i < shown.length; i++) {
      outline = Path.combine(
        PathOperation.union,
        outline,
        _bridge(shown[i - 1], shown[i]),
      );
    }
    return outline;
  }

  /// The liquid neck between parts [a] and [b]. Close together, it is as
  /// thick as the smaller part, so the two read as one drop. Apart, it
  /// thins to the bridge waist.
  Path _bridge(Rect a, Rect b) {
    final center = a.center.dy;
    final link = ((b.left - a.right) / _IslandMetrics.bridgeLength).clamp(
      0.0,
      1.0,
    );
    // The neck leaves each cap 50° above and below its axis.
    const cos50 = 0.643;
    const sin50 = 0.766;
    final aRadius = a.height / 2;
    final bRadius = b.height / 2;
    final aX = a.right - aRadius * (1 - cos50);
    final bX = b.left + bRadius * (1 - cos50);
    final aY = aRadius * sin50;
    final bY = bRadius * sin50;
    final waist =
        lerpDouble(
          math.min(a.height, b.height),
          _IslandMetrics.bridgeWaist,
          link,
        )! /
        2;
    // The control point puts the middle of each curve at the waist.
    final control = 2 * waist - (aY + bY) / 2;
    final middle = (aX + bX) / 2;
    return Path()
      ..moveTo(aX, center - aY)
      ..quadraticBezierTo(middle, center - control, bX, center - bY)
      ..lineTo(bX, center + bY)
      ..quadraticBezierTo(middle, center + control, aX, center + aY)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outline = _outline();
    final bounds = outline.getBounds();
    if (bounds.isEmpty) return;

    for (final shadow in glass.controlShadows) {
      canvas.drawPath(
        outline.shift(shadow.offset),
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma),
      );
    }
    for (final tint in glass.tints) {
      canvas.drawPath(outline, Paint()..color = tint);
    }
    canvas.drawPath(
      outline,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: glass.sheen,
          stops: const [0, 0.55, 1],
        ).createShader(bounds),
    );

    // The glow and the rim stay inside the outline: a stroke centered on
    // the edge, clipped to the shape, keeps only its inner half.
    canvas.save();
    canvas.clipPath(outline);
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [glass.edgeGlow, glass.edgeGlow.withValues(alpha: 0)],
        ).createShader(bounds),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: glass.rim,
        ).createShader(bounds),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IslandPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.glass != glass;
}

/// A sync icon that turns slowly while the wallet loads.
///
/// When it does not spin, it stays at the angle of [wind], from where the
/// spin left it: it winds as a pull brings the loading part in, and
/// unwinds as the part leaves. A spin starts from that angle too, so the
/// icon never jumps. With reduced motion it does not spin.
class _SyncIcon extends StatefulWidget {
  const _SyncIcon({
    required this.size,
    required this.color,
    required this.spinning,
    required this.wind,
  });

  final double size;
  final Color color;

  /// The wallet loads.
  final bool spinning;

  /// The angle while the icon does not spin, in turns.
  final double wind;

  @override
  State<_SyncIcon> createState() => _SyncIconState();
}

class _SyncIconState extends State<_SyncIcon>
    with SingleTickerProviderStateMixin {
  /// One full turn.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: Motion.durationShimmer,
  );

  /// Added to [_SyncIcon.wind] while the icon does not spin, so that it
  /// stays where the spin stopped.
  double _windOffset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spinOrStop(widget.wind);
  }

  @override
  void didUpdateWidget(_SyncIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _spinOrStop(oldWidget.wind);
  }

  void _spinOrStop(double lastWind) {
    final spin = widget.spinning && !Motion.isReduced(context);
    if (spin && !_turn.isAnimating) {
      _turn.value = (_windOffset + lastWind) % 1;
      _turn.repeat();
    } else if (!spin && _turn.isAnimating) {
      _windOffset = _turn.value - widget.wind;
      _turn.stop();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The sync glyph turns clockwise, so the turn goes the same way.
    return AnimatedBuilder(
      animation: _turn,
      builder: (context, child) => Transform.rotate(
        angle:
            (_turn.isAnimating ? _turn.value : _windOffset + widget.wind) *
            2 *
            math.pi,
        child: child,
      ),
      child: Icon(Icons.sync_rounded, size: widget.size, color: widget.color),
    );
  }
}
