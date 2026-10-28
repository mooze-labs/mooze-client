import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Scales [child] down while a pointer presses it.
///
/// Wrap only the visual part of a button. The wrapped button keeps its tap
/// handler and its semantics, because [Listener] does not take part in the
/// gesture arena.
///
/// With reduced motion, the scale does not change. The button keeps its ink
/// overlay as the press feedback.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.scale = Motion.pressScale,
  });

  final Widget child;

  /// Scale while pressed. Use [Motion.pressScaleCircle] for circle buttons.
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.isReduced(context);
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed && !reduced ? widget.scale : 1,
        duration: Motion.of(context, Motion.durationPress),
        curve: Motion.curveMove,
        child: widget.child,
      ),
    );
  }
}
