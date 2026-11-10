import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One segment of a [GlassSegmentedControl].
@immutable
class GlassSegment<T> {
  const GlassSegment({
    required this.value,
    required this.label,
    this.builder,
    this.enabled = true,
  });

  final T value;

  /// The text of the segment, and its name for screen readers.
  final String label;

  /// Builds the content of the segment in place of [label], for example a
  /// title over two detail lines. It gets whether the segment is under the
  /// lens. [label] still names the segment for screen readers, so it says
  /// what the content shows.
  final Widget Function(BuildContext context, bool selected)? builder;

  /// A disabled segment, for example one whose content still loads, takes
  /// no tap, and a drag released over it springs back.
  final bool enabled;
}

/// A segmented control made of Liquid Glass, with the lens of the floating
/// navigation bar.
///
/// A glass lens marks the selected segment. It slides to a tapped segment
/// and stretches while it moves, like a drop of liquid. Each segment is as
/// wide as its label, so the lens takes the width of the segment it
/// reaches.
///
/// The control can also be dragged sideways. The lens follows the finger,
/// stretches between segments, presses against the ends, and the label
/// under it lights up with a selection click. On release, the drag and its
/// speed pick the segment, the lens settles there on a [Motion.springSettle]
/// spring, and the control calls [onChanged], as a tap would. A drag never
/// calls [onChanged] on the way: the value changes once, on release.
///
/// With no segment selected, the lens fades out where it is. A tap brings
/// it back on the tapped segment, and a drag brings it back under the
/// finger.
///
/// With reduced motion, the lens jumps, does not stretch, and shows or
/// hides at once. A drag still moves it with the finger.
class GlassSegmentedControl<T> extends StatefulWidget {
  const GlassSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expand = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
  });

  final List<GlassSegment<T>> segments;

  /// The value of the selected segment. Null, or a value of no segment,
  /// selects none.
  final T? selected;

  final ValueChanged<T> onChanged;

  /// Shares the width of the control among the segments in equal parts.
  /// Otherwise each segment is as wide as its label.
  final bool expand;

  /// Corners of the track. The lens has the same corners less the [inset],
  /// so the two curves stay parallel.
  final BorderRadius borderRadius;

  /// Space between the track and the segments.
  static const double inset = 3;

  /// Smallest height of a segment. With [inset], the control is a 48 pt
  /// touch row.
  static const double segmentHeight = 42;

  /// Smallest width of a segment.
  static const double minSegmentWidth = 48;

  /// Space on each side of a label.
  static const double labelPadding = 12;

  @override
  State<GlassSegmentedControl<T>> createState() =>
      _GlassSegmentedControlState<T>();
}

class _GlassSegmentedControlState<T> extends State<GlassSegmentedControl<T>>
    with TickerProviderStateMixin {
  /// Moves the lens between two segments.
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
    value: 1,
  );

  /// Start and end of the current lens move, as segment positions.
  late double _from;
  late double _to;

  /// Lens position during a drag and while it settles after one. Null
  /// otherwise.
  double? _dragPosition;

  /// Settles the lens after a drag, in segment positions.
  late final AnimationController _settle;

  /// True from the start of a drag until the lens settles.
  bool _dragging = false;

  /// Center of the lens at the start of the drag, and the travel of the
  /// finger since, in logical pixels.
  double _dragStartCenter = 0;
  double _dragDistance = 0;

  /// Segment under the lens during a drag.
  int _dragSegment = 0;

  /// Shows the lens at 1 and hides it at 0, while no segment is selected.
  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
    value: _selectedIndex < 0 ? 0 : 1,
  );

  /// The segment boxes from the last build.
  _Layout _layout = const _Layout([], []);

  /// Share of the travel past the first or the last segment that the lens
  /// follows. The lens presses against the end instead of leaving it.
  static const double _edgeResistance = 0.3;

  /// Time over which the release speed carries the lens on, in seconds. A
  /// flick moves to the next segment even after a short drag.
  static const double _flingTime = 0.12;

  /// The index of the selected segment, or -1 with none.
  int get _selectedIndex => _indexOf(widget.selected);

  int _indexOf(T? value) =>
      widget.segments.indexWhere((segment) => segment.value == value);

  int get _last => widget.segments.length - 1;

  @override
  void initState() {
    super.initState();
    _from = _to = math.max(0, _selectedIndex).toDouble();
    _settle = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => _dragPosition = _settle.value));
  }

  @override
  void didUpdateWidget(GlassSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _selectedIndex;
    final sameSegments = listEquals(
      [for (final segment in oldWidget.segments) segment.value],
      [for (final segment in widget.segments) segment.value],
    );
    if (!sameSegments) {
      // Other segments, for example of another asset: the lens takes its
      // place at once.
      _settle.stop();
      _dragging = false;
      _dragPosition = null;
      _from = _to = math.max(0, index).toDouble();
      _move.value = 1;
      _presence.value = index < 0 ? 0 : 1;
      return;
    }
    // During a drag, the lens settles on the new segment itself.
    if (oldWidget.selected == widget.selected || _dragging) return;
    if (index < 0) {
      _showLens(false);
    } else if (_indexOf(oldWidget.selected) < 0) {
      // The lens comes back on the new segment, not from where it left.
      setState(() {
        _from = _to = index.toDouble();
        _move.value = 1;
      });
      _showLens(true);
    } else {
      _moveTo(index);
    }
  }

  @override
  void dispose() {
    _presence.dispose();
    _settle.dispose();
    _move.dispose();
    super.dispose();
  }

  void _showLens(bool show) {
    if (Motion.isReduced(context)) {
      _presence.value = show ? 1 : 0;
    } else if (show) {
      _presence.forward();
    } else {
      _presence.reverse();
    }
  }

  /// Visual position of the lens, as a segment position.
  double get _position =>
      _dragPosition ??
      lerpDouble(_from, _to, Motion.curveLargeMove.transform(_move.value))!;

  /// Stretch of the lens from 0 (at rest) to 1 (halfway between segments
  /// two apart).
  double get _stretch {
    if (Motion.isReduced(context)) return 0;
    final drag = _dragPosition;
    if (drag != null) {
      return math.sin(math.pi * (drag - drag.floorToDouble()));
    }
    final distance = (_to - _from).abs().clamp(0.0, 2.0) / 2;
    return math.sin(math.pi * _move.value) * distance;
  }

  void _moveTo(int index) {
    final target = index.toDouble();
    final start = _position;
    _dragPosition = null;
    if ((start - target).abs() < 0.02 || Motion.isReduced(context)) {
      setState(() {
        _from = _to = target;
        _move.value = 1;
      });
      return;
    }
    _from = start;
    _to = target;
    _move.forward(from: 0);
  }

  // Drag.

  void _onDragStart(DragStartDetails details) {
    _settle.stop();
    _move.stop();
    // With no segment selected, the lens comes up under the finger.
    final start = _selectedIndex < 0
        ? _layout
              .positionAt(details.localPosition.dx)
              .clamp(0.0, _last.toDouble())
        : _position;
    _showLens(true);
    _dragStartCenter = _layout.centerAt(start);
    _dragDistance = 0;
    _dragSegment = start.round().clamp(0, _last);
    setState(() {
      _dragging = true;
      _dragPosition = start;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta!;
    final position = _layout.positionAt(
      _dragStartCenter + _dragDistance,
      resistance: _edgeResistance,
    );
    final segment = position.round().clamp(0, _last);
    if (segment != _dragSegment) {
      _dragSegment = segment;
      HapticFeedback.selectionClick();
    }
    setState(() => _dragPosition = position);
  }

  void _onDragEnd(DragEndDetails details) {
    final position = _dragPosition ?? _position;
    final speed = details.primaryVelocity ?? 0;
    final center = _layout.centerAt(position);
    final release = _layout
        .positionAt(center + speed * _flingTime)
        .round()
        .clamp(0, _last);
    // Over a disabled segment, the lens springs back to the selected one.
    // With none, it settles there and hides.
    final target = widget.segments[release].enabled || _selectedIndex < 0
        ? release
        : _selectedIndex;
    if (widget.segments[target].enabled && target != _selectedIndex) {
      widget.onChanged(widget.segments[target].value);
    }
    _settleTo(target, speed / _layout.spacingAt(position));
  }

  /// A drag that never started, for example because a tap won, leaves the
  /// lens alone.
  void _onDragCancel() {
    if (_dragging) {
      final target = _selectedIndex < 0
          ? _position.round().clamp(0, _last)
          : _selectedIndex;
      _settleTo(target, 0);
    }
  }

  /// Springs the lens from where the finger left it to [target], with the
  /// release speed in segments per second.
  void _settleTo(int target, double velocity) {
    final start = _dragPosition ?? _position;
    if (Motion.isReduced(context) || (start - target).abs() < 0.001) {
      _endDrag(target);
      return;
    }
    _settle.value = start;
    _settle
        .animateWith(
          SpringSimulation(
            Motion.springSettle,
            start,
            target.toDouble(),
            velocity,
            snapToEnd: true,
          ),
        )
        // A new drag stops the spring, and the future then never completes.
        .then((_) => _endDrag(target));
  }

  void _endDrag(int target) {
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _dragPosition = null;
      _from = _to = target.toDouble();
      _move.value = 1;
    });
    // The parent kept another value, or none.
    if (_selectedIndex < 0) {
      _showLens(false);
    } else if (_selectedIndex != target) {
      _moveTo(_selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    // One weight for every label, so a segment keeps its width when the
    // selection changes.
    final style = context.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return LiquidGlass(
      borderRadius: widget.borderRadius,
      blurBackdrop: false,
      shadows: GlassStyle.of(context).controlShadows,
      child: Padding(
        padding: const EdgeInsets.all(GlassSegmentedControl.inset),
        child: widget.expand
            ? LayoutBuilder(
                builder: (context, constraints) => _track(
                  context,
                  constraints.hasBoundedWidth
                      ? _Layout.equal(
                          widget.segments.length,
                          constraints.maxWidth,
                        )
                      : _Layout.measure(context, widget.segments, style),
                  style,
                ),
              )
            : _track(
                context,
                _Layout.measure(context, widget.segments, style),
                style,
              ),
      ),
    );
  }

  /// The segments over the lens, in [layout].
  Widget _track(BuildContext context, _Layout layout, TextStyle? style) {
    _layout = layout;
    // The label under the lens lights up during a drag.
    final highlighted = _dragging
        ? _position.round().clamp(0, _last)
        : _selectedIndex;
    final lensRadius =
        widget.borderRadius -
        const BorderRadius.all(Radius.circular(GlassSegmentedControl.inset));

    // The tallest segment sets the height of the row.
    final segments = IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.segments.length; i++)
            _SegmentLabel(
              width: layout.widths[i],
              segment: widget.segments[i],
              style: style,
              selected: highlighted == i,
              onTap: () {
                if (i != _selectedIndex) {
                  widget.onChanged(widget.segments[i].value);
                }
              },
            ),
        ],
      ),
    );

    // Only horizontal drags: vertical ones stay with the page, and a tap
    // without travel stays with its segment.
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_move, _presence]),
              builder: (context, _) {
                final presence = Motion.curveEnter.transform(_presence.value);
                return CustomSingleChildLayout(
                  delegate: _LensLayout(layout, _position, _stretch),
                  // The lens grows in from a drop, and shrinks back.
                  child: Opacity(
                    opacity: presence,
                    child: Transform.scale(
                      scale: lerpDouble(0.8, 1, presence)!,
                      child: GlassLens(borderRadius: lensRadius),
                    ),
                  ),
                );
              },
            ),
          ),
          segments,
        ],
      ),
    );
  }
}

/// The boxes of the segments, side by side.
@immutable
class _Layout {
  const _Layout(this.widths, this.lefts);

  final List<double> widths;
  final List<double> lefts;

  /// [count] segments that share [width] in equal parts.
  factory _Layout.equal(int count, double width) {
    final each = count == 0 ? 0.0 : width / count;
    return _Layout(List.filled(count, each), [
      for (var i = 0; i < count; i++) i * each,
    ]);
  }

  factory _Layout.measure(
    BuildContext context,
    List<GlassSegment<Object?>> segments,
    TextStyle? style,
  ) {
    final widths = <double>[];
    final lefts = <double>[];
    var left = 0.0;
    for (final segment in segments) {
      // The labels take [style] as their whole default style, so the
      // measure uses it alone too.
      final painter = TextPainter(
        text: TextSpan(text: segment.label, style: style),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = math.max(
        GlassSegmentedControl.minSegmentWidth,
        (painter.width + GlassSegmentedControl.labelPadding * 2).ceilToDouble(),
      );
      painter.dispose();
      widths.add(width);
      lefts.add(left);
      left += width;
    }
    return _Layout(widths, lefts);
  }

  double get total => widths.fold(0, (sum, width) => sum + width);

  double _center(int index) => lefts[index] + widths[index] / 2;

  /// Center of the lens at [position], a segment index or a point between
  /// two.
  double centerAt(double position) {
    if (widths.length < 2) return widths.isEmpty ? 0 : _center(0);
    final from = position.floor().clamp(0, widths.length - 2).toInt();
    return lerpDouble(_center(from), _center(from + 1), position - from)!;
  }

  /// Distance between the centers around [position].
  double spacingAt(double position) {
    if (widths.length < 2) return 1;
    final from = position.floor().clamp(0, widths.length - 2).toInt();
    return math.max(1.0, _center(from + 1) - _center(from));
  }

  /// The segment position whose lens center is at [center]. Past the first
  /// and the last segment, the position moves by [resistance] of the
  /// travel.
  double positionAt(double center, {double resistance = 1}) {
    if (widths.length < 2) return 0;
    final last = widths.length - 1;
    if (center < _center(0)) {
      return (center - _center(0)) / spacingAt(0) * resistance;
    }
    if (center > _center(last)) {
      return last +
          (center - _center(last)) / spacingAt(last.toDouble()) * resistance;
    }
    var from = 0;
    while (from < last - 1 && center > _center(from + 1)) {
      from++;
    }
    return from + (center - _center(from)) / spacingAt(from.toDouble());
  }

  /// The lens box at [position], in a row [height] tall. It widens and
  /// flattens a little with [stretch], and stays inside the track.
  Rect lensAt(double position, double stretch, double height) {
    if (widths.isEmpty) return Rect.zero;
    final from = position
        .floor()
        .clamp(0, math.max(0, widths.length - 2))
        .toInt();
    final to = math.min(from + 1, widths.length - 1);
    final width = lerpDouble(
      widths[from],
      widths[to],
      (position - from).clamp(0.0, 1.0),
    )!;
    final lensWidth = math.min(width * (1 + 0.3 * stretch), total);
    final lensHeight = height * (1 - 0.12 * stretch);
    final left = (centerAt(position) - lensWidth / 2).clamp(
      0.0,
      total - lensWidth,
    );
    return Rect.fromLTWH(
      left,
      (height - lensHeight) / 2,
      lensWidth,
      lensHeight,
    );
  }
}

/// Puts the lens at its box, in the height of the row.
class _LensLayout extends SingleChildLayoutDelegate {
  _LensLayout(this.layout, this.position, this.stretch);

  final _Layout layout;
  final double position;
  final double stretch;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.tight(
        layout.lensAt(position, stretch, constraints.maxHeight).size,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      layout.lensAt(position, stretch, size.height).topLeft;

  @override
  bool shouldRelayout(_LensLayout oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.position != position ||
      oldDelegate.stretch != stretch;
}

/// One segment: its label, or its own content, over the lens.
class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.width,
    required this.segment,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final GlassSegment<Object?> segment;
  final TextStyle? style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = segment.enabled;
    final builder = segment.builder;
    // `excludeSemantics` drops the semantics of the gesture below, so the
    // node carries the tap action itself.
    return Semantics(
      button: true,
      enabled: enabled ? null : false,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: segment.label,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GlassSegmentedControl.segmentHeight,
            ),
            child: Center(
              child: builder != null
                  ? builder(context, selected)
                  : Padding(
                      // A large text scale makes the row taller.
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AnimatedDefaultTextStyle(
                        duration: Motion.of(context, Motion.durationFast),
                        curve: Motion.curveMove,
                        style: (style ?? const TextStyle()).copyWith(
                          color: selected
                              ? context.colors.textPrimary
                              : context.colors.textSecondary,
                        ),
                        child: Text(
                          segment.label,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
