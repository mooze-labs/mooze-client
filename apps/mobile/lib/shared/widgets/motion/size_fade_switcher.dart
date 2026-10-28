import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Grows and fades a new [child] in, and shrinks and fades the old one out.
///
/// Give each child a distinct key, so a change of key starts the switch.
/// The switch runs over [duration] with [Motion.curveEnter] in and
/// [Motion.curveExit] out. With reduced motion, the child changes at once.
class SizeFadeSwitcher extends StatelessWidget {
  const SizeFadeSwitcher({
    super.key,
    required this.child,
    this.duration = Motion.durationEmphasis,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    // `AnimatedSize` with a zero duration changes its own layout during
    // layout and asserts, so reduced motion skips it.
    if (Motion.isReduced(context)) return child;
    return AnimatedSize(
      duration: duration,
      curve: Motion.curveEnter,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Motion.curveEnter,
        switchOutCurve: Motion.curveExit,
        layoutBuilder: (current, previous) => Stack(
          alignment: alignment,
          children: [...previous, if (current != null) current],
        ),
        child: child,
      ),
    );
  }
}
