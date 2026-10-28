import 'package:flutter/material.dart';

/// Motion tokens for durations, curves, and springs.
///
/// The values come from the Material 3 motion tokens that Flutter exposes as
/// [Durations] and [Easing]. Values without a Material equivalent are
/// app proposals.
///
/// **Usage:**
/// ```dart
/// import 'package:mooze_mobile/themes/motion.dart';
///
/// AnimatedOpacity(
///   duration: Motion.of(context, Motion.durationFast),
///   curve: Motion.curveMove,
///   ...
/// )
/// ```
///
/// Use these tokens in widgets. Do not write raw `Duration` or `Curves`
/// values for UI motion. Read every duration through [Motion.of] so that
/// the system "reduce motion" setting removes the animation.
abstract final class Motion {
  // ── Durations ─────────────────────────────────────────────────────────────

  /// Press-down scale and key highlight (100 ms).
  static const durationPress = Durations.short2;

  /// Toggles, chips, icon swaps, and digit entry (150 ms).
  static const durationFast = Durations.short3;

  /// Exits, sheet close, and hold release (200 ms).
  static const durationExit = Durations.short4;

  /// Value change, skeleton to content, and banners (250 ms).
  static const durationBase = Durations.medium1;

  /// Section entrance, chart period change, list insert, and error shake
  /// (300 ms).
  static const durationEmphasis = Durations.medium2;

  /// Sheet open, Hero flight, and large container changes (400 ms).
  static const durationSlow = Durations.medium4;

  /// First reveal of a large chart (500 ms).
  static const durationChartDraw = Durations.long2;

  /// Full success sequence (800 ms).
  static const durationCelebrate = Durations.extralong2;

  /// Count-up of a balance from 0 to its value after a tap (700 ms). Use it
  /// only for a figure the user asked to see, never on screen open.
  static const durationCountUp = Duration(milliseconds: 700);

  /// Fill time of a hold-to-confirm control.
  static const durationHoldConfirm = Duration(milliseconds: 900);

  /// One skeleton shimmer cycle.
  static const durationShimmer = Duration(milliseconds: 1200);

  /// Delay between sibling entrances.
  static const staggerStep = Duration(milliseconds: 40);

  /// Maximum total time of a screen entrance.
  static const entranceBudget = Duration(milliseconds: 500);

  /// Minimum time between two animations of the same live value.
  ///
  /// Prices and balances can update many times per second. Show at most one
  /// value animation per interval and skip the intermediate values.
  static const numberChangeInterval = Duration(seconds: 1);

  // ── Curves ────────────────────────────────────────────────────────────────

  /// Elements that appear.
  static const curveEnter = Easing.emphasizedDecelerate;

  /// Elements that leave.
  static const curveExit = Easing.emphasizedAccelerate;

  /// Position, size, color, and value changes on screen.
  static const curveMove = Easing.standard;

  /// Large transforms, such as shared elements.
  static const curveLargeMove = Curves.easeInOutCubicEmphasized;

  /// Progress fills, shimmer, and scroll-linked effects.
  static const curveLinear = Easing.linear;

  // ── Springs ───────────────────────────────────────────────────────────────

  /// Drag release of sheets and cards. No bounce.
  static final springSettle = SpringDescription.withDurationAndBounce(
    duration: Durations.medium3,
  );

  /// Press release on buttons only. Never use it for numbers.
  static final springPress = SpringDescription.withDurationAndBounce(
    duration: Durations.medium1,
    bounce: 0.15,
  );

  // ── Composite values ──────────────────────────────────────────────────────

  /// Vertical distance of a fade-and-rise entrance and of a value change.
  static const riseDistance = 8.0;

  /// Scale of a pressed button.
  static const pressScale = 0.97;

  /// Scale of a pressed circle action button.
  static const pressScaleCircle = 0.94;

  // ── Reduced motion ────────────────────────────────────────────────────────

  /// Returns true when the system asks for reduced motion.
  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [Duration.zero] when the system asks for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      isReduced(context) ? Duration.zero : duration;

  /// Returns the duration of a staggered entrance with [sections] parts.
  ///
  /// The result is [durationEmphasis] plus one [staggerStep] per extra
  /// section.
  static Duration staggeredEntrance(int sections) =>
      durationEmphasis + staggerStep * (sections - 1);
}
