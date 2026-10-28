import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Shows a formatted amount and animates changes of the amount.
///
/// A changed [text] fades in and slides by [Motion.riseDistance]: up when
/// [value] increases, down when it decreases. The first value shows without
/// animation, so the amount never counts up from zero.
///
/// The widget animates at most once per [Motion.numberChangeInterval]. It
/// skips intermediate values and shows the latest value at the end of the
/// interval. Screen readers always get the latest [text] at once.
///
/// A change of [mode] (for example fiat to BTC) is not a value change. It
/// cross-fades without a slide and without the interval.
///
/// With reduced motion, the text changes at once.
class AnimatedAmount extends StatefulWidget {
  const AnimatedAmount({
    super.key,
    required this.text,
    this.value,
    this.mode,
    this.style,
    this.alignment = AlignmentDirectional.centerStart,
    this.semanticsLabel,
  });

  /// The formatted amount. Format the value before you pass it, so that
  /// the text changes only when the visible amount changes.
  final String text;

  /// The numeric value of [text]. It sets the slide direction. If it is
  /// null, a change only cross-fades.
  final double? value;

  /// The unit or display mode of [text].
  final Object? mode;

  final TextStyle? style;

  /// Alignment of the old and the new text during a change.
  final AlignmentGeometry alignment;

  /// Screen reader label. Defaults to [text].
  final String? semanticsLabel;

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount> {
  late String _shownText;
  double? _shownValue;
  Object? _shownMode;

  /// 1 slides up, -1 slides down, 0 only fades.
  int _direction = 0;

  /// Runs while a new animation must wait.
  Timer? _interval;

  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    // Set the shown value here, not in lazy field initializers. A lazy
    // initializer would run at the first read in didUpdateWidget and take
    // the new value.
    _shownText = widget.text;
    _shownValue = widget.value;
    _shownMode = widget.mode;
  }

  @override
  void didUpdateWidget(AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != _shownMode) {
      _show(direction: 0);
      return;
    }
    if (widget.text == _shownText) return;
    if (_reduced) {
      _show(direction: 0);
      return;
    }
    // A running interval shows the latest value when it ends.
    if (_interval?.isActive ?? false) return;
    _show(direction: _directionTo(widget.value));
    _startInterval();
  }

  int _directionTo(double? next) {
    final previous = _shownValue;
    if (previous == null || next == null || next == previous) return 0;
    return next > previous ? 1 : -1;
  }

  void _show({required int direction}) {
    _direction = direction;
    _shownText = widget.text;
    _shownValue = widget.value;
    _shownMode = widget.mode;
  }

  void _startInterval() {
    _interval = Timer(Motion.numberChangeInterval, _onIntervalEnd);
  }

  void _onIntervalEnd() {
    if (!mounted) return;
    if (widget.text == _shownText && widget.mode == _shownMode) return;
    setState(() => _show(direction: _directionTo(widget.value)));
    _startInterval();
  }

  @override
  void dispose() {
    _interval?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reduced = Motion.isReduced(context);
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    final textStyle = style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final lineHeight = (textStyle.fontSize ?? 14) * (textStyle.height ?? 1.2);
    final slide = Motion.riseDistance / lineHeight;
    final currentKey = ValueKey<Object>('$_shownMode|$_shownText');

    return Semantics(
      label: widget.semanticsLabel ?? widget.text,
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.durationBase),
        switchInCurve: Motion.curveEnter,
        switchOutCurve: Motion.curveExit,
        layoutBuilder: (current, previous) => Stack(
          alignment: widget.alignment,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) {
          if (_direction == 0) {
            return FadeTransition(opacity: animation, child: child);
          }
          // The new text enters from the side of the change. The old text
          // leaves to the opposite side.
          final incoming = child.key == currentKey;
          final begin = Offset(0, (incoming ? slide : -slide) * _direction);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: begin,
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          _shownText,
          key: currentKey,
          style: textStyle,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}
