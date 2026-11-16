import 'package:flutter/widgets.dart';

/// Runs [action] once the route of [context] has come in, or at once when
/// it has no entrance or its entrance is over.
///
/// A scene that starts under the page transition plays half hidden, and a
/// token that flies in from the screen before (see `StageHero`) would
/// still be in the air. Call it from `didChangeDependencies`.
void afterRouteEntrance(BuildContext context, VoidCallback action) {
  final route = ModalRoute.of(context);
  if (route == null) {
    action();
    return;
  }
  void check() {
    if (!context.mounted) return;
    // A HeroController lays out a page it pushes offstage for one frame, to
    // find its heroes, and meanwhile the animation of the page reads as
    // complete. Look again once the page is back onstage.
    if (route.offstage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => check());
      return;
    }
    final animation = route.animation;
    if (animation == null || animation.isCompleted) {
      action();
      return;
    }
    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(onStatus);
      if (context.mounted) action();
    }

    animation.addStatusListener(onStatus);
  }

  check();
}
