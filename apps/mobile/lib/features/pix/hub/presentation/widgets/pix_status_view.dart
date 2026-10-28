import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// State of an operation, as shown by [PixStatusView].
enum PixStatusKind { processing, success, failure, pending, warning, info }

/// The hero of a state screen: a large emblem, a title, and a message.
///
/// Every Pix state uses it: processing, success, failure, pending, and the
/// expired flow. The emblem shape carries the state together with its color:
/// a spinner, a check, a cross, an hourglass, or an alert.
///
/// When the state changes, the new emblem scales and fades in over
/// [Motion.durationEmphasis]. It never overshoots. With reduced motion it
/// changes at once. The title is a live region, so a screen reader announces
/// each new state.
class PixStatusView extends StatelessWidget {
  const PixStatusView({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.child,
  });

  /// Diameter of the emblem.
  static const double emblemSize = 88;

  final PixStatusKind kind;
  final String title;
  final String? message;

  /// Extra content below the message, for example the amount.
  final Widget? child;

  static PixTone toneOf(PixStatusKind kind) => switch (kind) {
    PixStatusKind.processing => PixTone.brand,
    PixStatusKind.success => PixTone.positive,
    PixStatusKind.failure => PixTone.negative,
    PixStatusKind.pending || PixStatusKind.warning => PixTone.warning,
    PixStatusKind.info => PixTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.durationEmphasis);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: duration,
          switchInCurve: Motion.curveEnter,
          switchOutCurve: Motion.curveExit,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: _Emblem(key: ValueKey(kind), kind: kind),
        ),
        const SizedBox(height: 24),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
        if (child != null) ...[const SizedBox(height: 20), child!],
      ],
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem({super.key, required this.kind});

  final PixStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final tone = PixStatusView.toneOf(kind);
    final color = pixToneColor(context, tone);
    const size = PixStatusView.emblemSize;
    final icon = switch (kind) {
      PixStatusKind.processing => null,
      PixStatusKind.success => PixIcons.check,
      PixStatusKind.failure => PixIcons.close,
      PixStatusKind.pending => PixIcons.pending,
      PixStatusKind.warning => PixIcons.warning,
      PixStatusKind.info => PixIcons.info,
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
        boxShadow: [
          // A soft halo of the state color, as the success glow of the
          // swap screen, kept faint.
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 32),
        ],
      ),
      child: icon == null
          ? SizedBox.square(
              dimension: size * 0.42,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
                // A still arc when animations are off.
                value: Motion.isReduced(context) ? 0.7 : null,
              ),
            )
          : PixIcon(icon, size: size * 0.42, color: color),
    );
  }
}
