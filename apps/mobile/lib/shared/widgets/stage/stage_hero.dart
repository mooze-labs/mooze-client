import 'package:flutter/material.dart';

/// How a screen whose scene holds the Mooze coin begins: the route that
/// opens it passes one as its extra (see [StageEntrance.of]).
enum StageEntrance {
  /// The scene enters on its own.
  standard,

  /// The Mooze coin is already there: it flies in from the screen before
  /// (see [StageHero.moozeCoin]) while the page fades in around it. The
  /// scene does not grow the coin in, and starts once it has landed.
  coinInPlace;

  /// The entrance that a route passed as [extra], [standard] if none.
  static StageEntrance of(Object? extra) =>
      extra is StageEntrance ? extra : standard;
}

/// A token that flies from the scene of one screen into the scene of the
/// next, so the two scenes read as one shot: the Mooze coin flies from the
/// end of the deleting screen into the onboarding.
///
/// Give the token the same [tag] in both scenes, at the same yaw, and open
/// the next screen with a fade: the token is then the one thing that
/// moves. The flight draws the token of the next scene scaled into the
/// rect between the two, so it keeps its proportions as its size changes.
/// Start the motion of the next scene once its route has come in (see
/// `afterRouteEntrance`), or the token lands on a scene that has moved on.
class StageHero extends StatelessWidget {
  const StageHero({super.key, required this.tag, required this.child});

  /// The tag of the Mooze coin.
  static const moozeCoin = 'stage.moozeCoin';

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Hero(tag: tag, flightShuttleBuilder: _shuttle, child: child);

  static Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final hero = toHeroContext.widget as Hero;
    final size = (toHeroContext.findRenderObject()! as RenderBox).size;
    return FittedBox(
      child: SizedBox.fromSize(size: size, child: hero.child),
    );
  }
}
