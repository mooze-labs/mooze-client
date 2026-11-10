import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The PIN digits as dots in a Liquid Glass capsule.
///
/// The PIN is never shown. An empty dot is a ring; a typed digit fills its
/// dot. Each change of [filled] grows the new dot in over
/// [Motion.durationFast].
///
/// A rise of [errorCount] shakes the capsule over
/// [Motion.durationEmphasis], and [hasError] paints the dots in the error
/// color until the next digit. With reduced motion the capsule does not
/// shake; the error color still shows.
///
/// Screen readers read how many digits are typed, never the digits.
class PinDots extends StatefulWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.errorCount = 0,
    this.hasError = false,
  });

  final int length;
  final int filled;

  /// Number of failed attempts so far. Each rise plays the shake once.
  final int errorCount;

  /// Paints the dots in the error color.
  final bool hasError;

  /// Size of one dot.
  static const double dotSize = 14;

  /// Space between two dots.
  static const double dotGap = 18;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: Motion.durationEmphasis,
  );

  /// Largest side offset of the shake.
  static const double _shakeDistance = 10;

  /// Number of back-and-forth moves in one shake.
  static const int _shakeCycles = 3;

  @override
  void didUpdateWidget(PinDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorCount > oldWidget.errorCount &&
        !Motion.isReduced(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final capsule = LiquidGlass(
      blurBackdrop: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 21),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: PinDots.dotGap),
              _Dot(filled: i < widget.filled, hasError: widget.hasError),
            ],
          ],
        ),
      ),
    );

    return Semantics(
      liveRegion: true,
      label: t.pin_digits_entered(widget.filled, widget.length),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _shake,
        child: capsule,
        builder: (context, child) {
          // A sine that fades out, so the capsule settles in place.
          final progress = _shake.value;
          final dx =
              math.sin(progress * math.pi * 2 * _shakeCycles) *
              _shakeDistance *
              (1 - progress);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.hasError});

  final bool filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final color = hasError
        ? context.colorScheme.error
        : context.colors.textPrimary;
    final duration = Motion.of(context, Motion.durationFast);

    return SizedBox.square(
      dimension: PinDots.dotSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The ring of an empty dot.
          AnimatedContainer(
            duration: duration,
            curve: Motion.curveMove,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: hasError
                    ? color
                    : context.colors.textSecondary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          // The fill grows from the center when a digit is typed.
          AnimatedScale(
            scale: filled ? 1 : 0,
            duration: duration,
            curve: filled ? Motion.curveEnter : Motion.curveExit,
            child: AnimatedContainer(
              duration: duration,
              curve: Motion.curveMove,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
