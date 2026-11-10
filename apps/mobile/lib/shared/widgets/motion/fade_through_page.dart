import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Returns a page that fades in and grows slightly into place.
///
/// Use it for a screen that replaces the whole stack, for example the PIN
/// screen right after the splash. A side slide suggests a step deeper into
/// a flow; here there is nothing to go back to, so the new screen rises out
/// of the old one instead.
///
/// The page below stays painted while the new page fades in, so the two
/// cross-fade without a flash. The page opens over [Motion.durationSlow]
/// with [Motion.curveEnter]. With reduced motion it appears at once.
CustomTransitionPage<T> fadeThroughPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    name: state.name ?? state.path,
    restorationId: state.pageKey.value,
    transitionDuration: Motion.of(context, Motion.durationSlow),
    reverseTransitionDuration: Motion.of(context, Motion.durationExit),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.curveEnter,
        reverseCurve: Motion.curveExit,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: _startScale, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Scale of the new page when it starts to fade in.
const double _startScale = 0.98;
