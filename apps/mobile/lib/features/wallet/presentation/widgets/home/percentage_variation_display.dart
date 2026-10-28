import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/shared/widgets/motion/animated_amount.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Shows a percentage change as an arrow, a sign, and a value.
///
/// The arrow and the sign show the direction. The color is a third signal.
/// Gains use the tertiary container colors, losses use the error container
/// colors, and no change uses neutral colors. All pairs pass 4.5:1 in the
/// light and the dark theme.
///
/// Color changes cross-fade and the arrow turns when the direction flips.
/// The value uses [AnimatedAmount].
class ChangeChip extends StatelessWidget {
  const ChangeChip({super.key, required this.percentage});

  final double percentage;

  /// Returns true when [percentage] shows as 0,00%.
  ///
  /// A change below half of 0,01% has no direction on screen. The chip
  /// shows it as no change, without an arrow and without a sign.
  static bool isFlat(double percentage) => (percentage * 100).round() == 0;

  /// Formats [percentage] with a sign, for example "+2,25%" or "−0,62%".
  static String format(BuildContext context, double percentage) {
    final number = NumberFormat(
      '0.00',
      Localizations.localeOf(context).toString(),
    ).format(percentage.abs());
    final sign = isFlat(percentage)
        ? ''
        : percentage > 0
        ? '+'
        : '−';
    return '$sign$number%';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isFlat = ChangeChip.isFlat(percentage);
    final isUp = !isFlat && percentage > 0;
    final isDown = !isFlat && percentage < 0;

    final background = isUp
        ? colorScheme.tertiaryContainer
        : isDown
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = isUp
        ? colorScheme.onTertiaryContainer
        : isDown
        ? colorScheme.onErrorContainer
        : context.colors.textSecondary;

    final duration = Motion.of(context, Motion.durationFast);
    final textStyle = context.textTheme.labelMedium?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
    );

    return AnimatedContainer(
      duration: duration,
      curve: Motion.curveMove,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUp || isDown) ...[
            AnimatedRotation(
              turns: isUp ? 0 : 0.5,
              duration: duration,
              curve: Motion.curveMove,
              child: Icon(Icons.arrow_upward, size: 12, color: foreground),
            ),
            const SizedBox(width: 2),
          ],
          AnimatedDefaultTextStyle(
            duration: duration,
            curve: Motion.curveMove,
            style: textStyle ?? const TextStyle(),
            // No explicit style: the text reads the animated default style,
            // so its color cross-fades with the container.
            child: AnimatedAmount(
              text: format(context, percentage),
              value: percentage,
            ),
          ),
        ],
      ),
    );
  }
}

/// A neutral chip for a change that is not available.
class UnavailableChangeChip extends StatelessWidget {
  const UnavailableChangeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'N/A',
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A skeleton in the shape of a [ChangeChip].
class LoadingChangeChip extends StatelessWidget {
  const LoadingChangeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: SkeletonBox(width: 60, height: 22, radius: 11),
    );
  }
}
