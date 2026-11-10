import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The hero of the biometric screens: a fingerprint in a Liquid Glass
/// circle with a soft brand glow behind it.
///
/// It grows and fades in once, over [Motion.durationSlow], without
/// overshoot. With reduced motion it appears at once.
class BiometricHero extends StatefulWidget {
  const BiometricHero({super.key});

  /// Size of the glass circle.
  static const double size = 112;

  @override
  State<BiometricHero> createState() => _BiometricHeroState();
}

class _BiometricHeroState extends State<BiometricHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;
    final hero = SizedBox.square(
      dimension: BiometricHero.size * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The glow is a radial light, not a blur, so it costs no filter.
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primary.withValues(alpha: 0.22),
                  primary.withValues(alpha: 0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          SizedBox.square(
            dimension: BiometricHero.size,
            child: LiquidGlass(
              blurBackdrop: false,
              child: Icon(Icons.fingerprint_rounded, size: 56, color: primary),
            ),
          ),
        ],
      ),
    );

    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(_animation),
          child: hero,
        ),
      ),
    );
  }
}
