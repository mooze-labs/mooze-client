import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A slider on Liquid Glass, from 0 to 1.
///
/// The track is a groove cut into the glass, filled up to the thumb with
/// [activeColor]. The thumb is a solid capsule. While the finger holds it,
/// it grows and clears into a glass lens, so the fill shows through it.
///
/// [marks] puts dots on the track, for example at preset values. The finger
/// feels the drag without a snap, with one haptic per move at most:
/// - a knock when the thumb reaches an end of the track;
/// - a tap when it reaches or crosses a mark;
/// - a click when it reaches a new value of [detentOf].
///
/// It keeps the gestures, the keyboard, and the semantics of [Slider].
class GlassSlider extends StatelessWidget {
  const GlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.marks = const [],
    this.detentOf,
    this.activeColor,
    this.semanticFormatterCallback,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  /// Positions of the dots on the track, from 0 to 1.
  final List<double> marks;

  /// The value that a slider position stands for, such as a rounded rate.
  /// The drag clicks each time it changes, as a picker wheel does.
  final Object? Function(double position)? detentOf;

  /// Fill of the track up to the thumb. Defaults to the primary text color,
  /// a neutral fill that leaves the brand color to the main action.
  final Color? activeColor;

  final SemanticFormatterCallback? semanticFormatterCallback;

  /// Height of the groove.
  static const double trackHeight = 6;

  /// Size of the thumb at rest.
  static const Size thumbSize = Size(34, 22);

  /// Height of the slider: a 48 pt touch row.
  static const double height = 48;

  void _onChanged(double next) {
    final previous = value;
    final crossed = marks.any(
      (mark) =>
          (previous - mark) * (next - mark) < 0 ||
          (next == mark && previous != mark),
    );
    final detent = detentOf;
    if ((next == 0 || next == 1) && next != previous) {
      HapticFeedback.mediumImpact();
    } else if (crossed) {
      HapticFeedback.lightImpact();
    } else if (detent != null && detent(next) != detent(previous)) {
      HapticFeedback.selectionClick();
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final glass = GlassStyle.of(context);
    final fill = activeColor ?? context.colors.textPrimary;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: trackHeight,
        activeTrackColor: fill,
        inactiveTrackColor: glass.groove,
        trackShape: _GlassTrackShape(
          marks: marks,
          // A dot reads on the fill and on the groove.
          markOnFill: context.colorScheme.surface.withValues(alpha: 0.6),
          markOnGroove: context.colors.textSecondary.withValues(alpha: 0.7),
        ),
        thumbShape: _GlassThumbShape(
          fill: glass.knobFill,
          clearFill: glass.lensFill,
          rim: glass.lensRim,
          // The control shadow, and the softer lens shadow that lifts it off
          // a light lens.
          shadows: [...glass.controlShadows, ...glass.lensShadows],
          glow: glass.edgeGlow,
        ),
        overlayShape: SliderComponentShape.noOverlay,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.never,
      ),
      child: SizedBox(
        height: height,
        child: Slider(
          value: value,
          onChanged: _onChanged,
          onChangeEnd: onChangeEnd,
          semanticFormatterCallback: semanticFormatterCallback,
        ),
      ),
    );
  }
}

/// The groove with the fill and the dots of the marks.
class _GlassTrackShape extends RoundedRectSliderTrackShape {
  const _GlassTrackShape({
    required this.marks,
    required this.markOnFill,
    required this.markOnGroove,
  });

  final List<double> marks;
  final Color markOnFill;
  final Color markOnGroove;

  static const double _markRadius = 1.5;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    // The fill keeps the height of the groove, so it reads as filling it.
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: 0,
    );
    final track = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final rtl = textDirection == TextDirection.rtl;
    for (final mark in marks) {
      final x = rtl
          ? track.right - mark * track.width
          : track.left + mark * track.width;
      final onFill = rtl ? x >= thumbCenter.dx : x <= thumbCenter.dx;
      context.canvas.drawCircle(
        Offset(x, track.center.dy),
        _markRadius,
        Paint()..color = onFill ? markOnFill : markOnGroove,
      );
    }
  }
}

/// A solid capsule that grows and clears into a glass lens while held.
class _GlassThumbShape extends SliderComponentShape {
  const _GlassThumbShape({
    required this.fill,
    required this.clearFill,
    required this.rim,
    required this.shadows,
    required this.glow,
  });

  /// Fill at rest.
  final Color fill;

  /// Fill while held: the clear glass of a lens.
  final Color clearFill;

  /// Rim colors, from top to bottom.
  final List<Color> rim;

  final List<BoxShadow> shadows;

  /// Light inside the edge of the held lens.
  final Color glow;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      GlassSlider.thumbSize;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final held = Motion.curveMove.transform(activationAnimation.value);
    final size = GlassSlider.thumbSize;
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * lerpDouble(1, 1.35, held)!,
      height: size.height * lerpDouble(1, 1.2, held)!,
    );
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );

    // The clear lens casts a lighter shadow, or the shadow would show
    // through it.
    for (final shadow in shadows) {
      final paint = shadow.toPaint()
        ..color = shadow.color.withValues(
          alpha: shadow.color.a * lerpDouble(1, 0.3, held)!,
        );
      canvas.drawRRect(
        shape.shift(shadow.offset).inflate(shadow.spreadRadius),
        paint,
      );
    }
    canvas.drawRRect(
      shape,
      Paint()..color = Color.lerp(fill, clearFill, held)!,
    );
    if (held > 0) {
      canvas.drawRRect(
        shape.deflate(2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
          ..color = glow.withValues(alpha: glow.a * held),
      );
    }
    canvas.drawRRect(
      shape.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: rim,
        ).createShader(rect),
    );
  }
}
