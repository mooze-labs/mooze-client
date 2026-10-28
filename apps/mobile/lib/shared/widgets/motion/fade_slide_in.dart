import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Fades [child] in and lifts it by [distance] as [animation] runs.
///
/// Drive several sections from one controller with [staggeredAnimation].
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.animation,
    required this.child,
    this.distance = Motion.riseDistance,
  });

  final Animation<double> animation;
  final Widget child;
  final double distance;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, distance * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Returns the entrance animation of section [index] from [controller].
///
/// Section [index] starts [index] × [Motion.staggerStep] after the first
/// section. Each section runs for [Motion.durationEmphasis] with
/// [Motion.curveEnter]. Set the controller duration with
/// [Motion.staggeredEntrance].
Animation<double> staggeredAnimation(
  AnimationController controller,
  int index,
) {
  final total = controller.duration!.inMicroseconds;
  final start = (index * Motion.staggerStep.inMicroseconds / total).clamp(
    0.0,
    1.0,
  );
  final end = (start + Motion.durationEmphasis.inMicroseconds / total).clamp(
    start,
    1.0,
  );
  return CurvedAnimation(
    parent: controller,
    curve: Interval(start, end, curve: Motion.curveEnter),
  );
}
