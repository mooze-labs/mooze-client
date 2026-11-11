import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A track whose thumb the user slides to the end to confirm an action, such
/// as a send or a swap. It fills the width it gets.
///
/// The thumb follows the finger. A release past 80% of the track confirms at
/// once: a medium haptic plays, [onSlideComplete] runs, and the thumb goes
/// to the end. It waits there with a spinner while [isLoading] is true, and
/// returns to the start when the loading ends, as after a failure. When the
/// callback starts no loading by the next frame, as when the screen cannot
/// confirm yet, the thumb returns at once. An earlier release springs the
/// thumb back.
///
/// While [isLoading] is true or [isEnabled] is false, the thumb does not
/// move, and a drag in progress lets go of it. A tap nudges the thumb to
/// show that it slides. With a screen reader, a tap confirms.
class SlideToConfirmButton extends StatefulWidget {
  final VoidCallback onSlideComplete;
  final String text;
  final bool isLoading;
  final bool isEnabled;

  const SlideToConfirmButton({
    super.key,
    required this.onSlideComplete,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  State<SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<SlideToConfirmButton>
    with SingleTickerProviderStateMixin {
  static const _height = 56.0;
  static const _inset = 4.0;
  static const _thumbSize = _height - _inset * 2;

  /// The share of the track past which a release confirms.
  static const _confirmAt = 0.8;

  /// How far a tap moves the thumb before it springs back.
  static const _nudgeDistance = 28.0;

  static const _dimmedOpacity = 0.4;
  static const _trailOpacity = 0.18;

  /// Where the thumb is, from the start (0) to the end (1) of the track.
  late final AnimationController _progress = AnimationController(vsync: this);

  /// The label fades out as the thumb slides over it, and is gone before the
  /// thumb covers its middle.
  late final Animation<double> _labelFade = _progress.drive(
    Tween<double>(
      begin: 1,
      end: 0,
    ).chain(CurveTween(curve: const Interval(0, 0.4))),
  );

  /// The distance that the thumb travels, from the last layout.
  double _travel = 1;

  bool _dragging = false;
  double _dragStartX = 0;
  double _dragStartProgress = 0;

  /// The thumb is past [_confirmAt] during a drag, so a release confirms.
  bool _armed = false;

  /// The slide confirmed. The thumb stays at the end until the screen ends
  /// its loading.
  bool _confirmed = false;

  bool get _interactive => widget.isEnabled && !widget.isLoading && !_confirmed;

  @override
  void didUpdateWidget(SlideToConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_confirmed) {
      if (oldWidget.isLoading && !widget.isLoading) _returnToStart();
      return;
    }
    final wasInteractive = oldWidget.isEnabled && !oldWidget.isLoading;
    if (wasInteractive && !_interactive) {
      // A loading that the screen starts by itself, as a quote refresh,
      // lets go of the thumb, even during a drag: a release must not
      // confirm what the screen is changing.
      _dragging = false;
      _armed = false;
      if (_progress.value > 0) _settle(0);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!_interactive) return;
    _progress.stop();
    _dragging = true;
    _dragStartX = details.globalPosition.dx;
    _dragStartProgress = _progress.value;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    // The thumb keeps the point of the finger that grabbed it.
    final moved = details.globalPosition.dx - _dragStartX;
    _progress.value = (_dragStartProgress + moved / _travel).clamp(0.0, 1.0);
    final armed = _progress.value >= _confirmAt;
    if (armed == _armed) return;
    // The tick tells that a release now confirms.
    if (armed) HapticFeedback.selectionClick();
    setState(() => _armed = armed);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    if (_armed) {
      _confirm();
    } else {
      _settle(0, velocity: (details.primaryVelocity ?? 0) / _travel);
    }
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    setState(() => _armed = false);
    _settle(0);
  }

  void _onTap() {
    if (!_interactive) return;
    if (MediaQuery.accessibleNavigationOf(context)) {
      _confirm();
    } else {
      _nudge();
    }
  }

  void _confirm() {
    setState(() {
      _confirmed = true;
      _armed = false;
    });
    HapticFeedback.mediumImpact();
    _settle(1);
    // The callback starts the loading of the screen, which arrives with the
    // next frame. A callback that starts none, as when the screen cannot
    // confirm yet, gives the thumb back.
    SchedulerBinding.instance.endOfFrame.then((_) {
      if (mounted && _confirmed && !widget.isLoading) {
        setState(_returnToStart);
      }
    });
    widget.onSlideComplete();
  }

  void _returnToStart() {
    _confirmed = false;
    _armed = false;
    _settle(0);
  }

  /// Moves the thumb a little toward the end and back, to show that it
  /// slides.
  void _nudge() {
    if (Motion.isReduced(context) || _progress.isAnimating) return;
    final peak = math.min(_nudgeDistance / _travel, _confirmAt / 2);
    _progress
        .animateTo(
          peak,
          duration: Motion.durationBase,
          curve: Motion.curveEnter,
        )
        .then((_) {
          if (mounted && !_dragging && !_confirmed) _settle(0);
        });
  }

  /// Springs the thumb to [target], or puts it there under reduced motion.
  void _settle(double target, {double velocity = 0}) {
    if (Motion.isReduced(context)) {
      _progress.value = target;
      return;
    }
    _progress.animateWith(
      SpringSimulation(
        Motion.springSettle,
        _progress.value,
        target,
        velocity,
        // The spring ends within a tolerance: the thumb must rest exactly at
        // the start or at the end.
        snapToEnd: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final fade = Motion.of(context, Motion.durationFast);
    final label = widget.isLoading ? t.common_processing : widget.text;
    final dimmed = !_confirmed && (!widget.isEnabled || widget.isLoading);

    final caption = FadeTransition(
      opacity: _confirmed ? kAlwaysCompleteAnimation : _labelFade,
      child: Padding(
        // The label sits between the start and the end of the thumb.
        padding: const EdgeInsets.symmetric(horizontal: _height),
        child: Center(
          child: AnimatedSwitcher(
            duration: fade,
            child: FittedBox(
              key: ValueKey(label),
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: colors.onPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final checked = _confirmed || _armed;
    final thumb = GestureDetector(
      behavior: HitTestBehavior.opaque,
      // The drag starts where the finger went down, so the thumb does not
      // lag behind it by the touch slop.
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: Padding(
        padding: const EdgeInsets.all(_inset),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.onPrimaryColor,
            shape: const CircleBorder(),
            shadows: [
              BoxShadow(
                color: context.colorScheme.shadow.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: _thumbSize,
            child: Center(
              child: AnimatedSwitcher(
                duration: fade,
                child: widget.isLoading
                    ? SizedBox.square(
                        key: const ValueKey('loading'),
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.primaryColor,
                        ),
                      )
                    : Icon(
                        checked
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        key: ValueKey(checked),
                        color: colors.primaryColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: _interactive,
      label: label,
      onTap: _interactive ? _confirm : null,
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          opacity: dimmed ? _dimmedOpacity : 1,
          duration: fade,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            child: SizedBox(
              width: double.infinity,
              height: _height,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: colors.primaryColor,
                  shape: const StadiumBorder(),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // The thumb, with its inset, ends at the end of the
                    // track, whatever the width of the screen.
                    _travel = math.max(constraints.maxWidth - _height, 1);
                    return AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        final offset = _progress.value * _travel;
                        return Stack(
                          children: [
                            // The trail fills the track behind the thumb.
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: offset + _height,
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  color: colors.onPrimaryColor.withValues(
                                    alpha: _trailOpacity,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                            Positioned.fill(child: caption),
                            Positioned(
                              left: offset,
                              top: 0,
                              bottom: 0,
                              child: thumb,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
