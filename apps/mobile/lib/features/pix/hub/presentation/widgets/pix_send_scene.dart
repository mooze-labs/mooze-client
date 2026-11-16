import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_face.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Where the scene of a Pix send is in its motion.
@immutable
class PixSendMotion {
  const PixSendMotion({
    this.entrance = 1,
    this.wait = 0,
    this.delivered = 0,
    this.returned = 0,
  });

  /// The entrance of the DePix coin, from 0 to 1 over
  /// [Motion.durationPixSendEntrance].
  final double entrance;

  /// Where the wait is in its cycle, from 0 to 1 over
  /// [Motion.durationPixSendWait]. Every motion of the wait is periodic, so
  /// the loop wraps from 1 to 0 with no jump.
  final double wait;

  /// The turn of a delivered Pix, from 0 to 1 over
  /// [Motion.durationPixDelivered].
  final double delivered;

  /// The fall of a Pix not paid, from 0 to 1 over
  /// [Motion.durationPixReturned].
  final double returned;
}

/// The art of the result of a Pix send: the DePix the wallet sent becomes
/// the Pix the recipient gets.
///
/// - **Entrance**: the DePix coin grows in, its light comes up, and its
///   ring appears.
/// - **Wait**, while the Pix provider pays: the coin sways, its light
///   breathes, its ring turns once a cycle, and a soft wave leaves it, as a
///   sonar.
/// - **Delivered**, over [PixSendMotion.delivered]:
///
/// | Delivered    | What happens                                          |
/// |--------------|-------------------------------------------------------|
/// | 0            | The coin starts to spin up. A light haptic.           |
/// | 0 → 0.42     | It spins faster and faster and lifts, while particles |
/// |              | of DePix gather into it and its light grows.          |
/// | **0.42**     | **Peak**: edge-on, the coin becomes the Pix token, a  |
/// |              | diamond. Flash, shockwaves, burst, a heavy haptic.    |
/// | 0.42 → 0.68  | It turns on, snaps past its rest and back, and lands. |
/// |              | A light haptic.                                       |
/// | 0.5 → 1      | A second ring, a beam of light, the floor; sparkles.  |
///
/// - **Returned**, when the provider did not pay: no change of face. The
///   coin comes back to rest and sinks a little, its light dims, its ring
///   drifts away, and embers fall.
///
/// Everything is in the brand tint, as the other stages. It is decorative:
/// the title of the screen tells the state.
class PixSendScene extends StatelessWidget {
  const PixSendScene({super.key, required this.motion});

  final PixSendMotion motion;

  /// Height of the stage. The shockwave reaches past it.
  static const double height = 250;

  /// Width of the coin and of the Pix token.
  static const double coinSize = 120;

  /// Delivered at which the coin is edge-on and becomes the Pix token.
  static const double revealAt = 0.42;

  /// Delivered at which the Pix token lands.
  static const double landAt = 0.68;

  /// Yaw of the coin at rest, turned to show its edge.
  static const double restYaw = 0.36;

  /// The turn at which the coin is edge-on and becomes the Pix token: after
  /// a turn and a quarter.
  static const double _reveal = 2.5 * math.pi;

  /// The ring of the wait. Its head turns once a cycle, so the loop wraps
  /// with no jump.
  static const _waitRing = StageRing(
    width: 1.6,
    height: 0.42,
    tilt: 0.24,
    turns: -1,
    phase: 2.6,
  );

  /// Where the coin is in [motion]: its [turn], before it is folded into a
  /// yaw; its [lift], up is negative; its [scale] and [opacity]; and
  /// whether it [showsPix], the Pix token, rather than the DePix coin.
  ///
  /// The turn speeds up to edge-on and slows down after it, in two halves,
  /// so edge-on falls at [revealAt] wherever the sway stopped.
  @visibleForTesting
  static ({
    double turn,
    double lift,
    double scale,
    double opacity,
    bool showsPix,
  })
  poseAt(PixSendMotion motion) {
    final d = motion.delivered;
    final r = motion.returned;
    final sway = restYaw + 0.16 * math.sin(2 * math.pi * motion.wait);
    final double turn;
    if (d > 0) {
      // Faster and faster: an exact cubic, so the turn reaches edge-on
      // with no jump.
      final spin = stageProgress(d, 0, revealAt);
      turn = d < revealAt
          ? lerpDouble(sway, _reveal, spin * spin * spin)!
          : lerpDouble(
              _reveal,
              3 * math.pi + restYaw,
              Curves.easeOutBack.transform(stageProgress(d, revealAt, landAt)),
            )!;
    } else {
      // A Pix not paid: the coin comes back to rest.
      turn = lerpDouble(
        sway,
        restYaw,
        Curves.easeInOutSine.transform(stageProgress(r, 0, 0.5)),
      )!;
    }
    final grow = Curves.easeOutBack.transform(
      stageProgress(motion.entrance, 0, 0.6),
    );
    final swell = math.sin(
      math.pi * stageProgress(d, revealAt - 0.04, revealAt + 0.2),
    );
    final sink = Curves.easeInOutCubic.transform(stageProgress(r, 0.1, 0.7));
    return (
      turn: turn,
      lift: -14 * math.sin(math.pi * stageProgress(d, 0, landAt)) + 10 * sink,
      scale:
          lerpDouble(0.82, 1, grow)! * (1 + 0.08 * swell) * (1 - 0.05 * sink),
      opacity: stageProgress(motion.entrance, 0, 0.3),
      showsPix: turn >= _reveal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final palette = StagePalette.of(context);
    // The shockwave crosses the whole screen.
    final reach = MediaQuery.sizeOf(context).longestSide;
    final pose = poseAt(motion);
    final m = motion;
    final e = m.entrance;
    final d = m.delivered;
    final r = m.returned;

    StageEffects effects(Canvas canvas) => StageEffects(
      canvas,
      tint: brand,
      light: palette.highlight(brand),
      radius: radius,
    );

    // The light of the coin: it comes in, breathes while the provider
    // pays, grows with the spin and gives way to the light of the Pix, or
    // dims when the Pix is not paid.
    final breath =
        stageProgress(e, 0, 0.5) *
        (0.6 + 0.12 * math.sin(2 * math.pi * m.wait));
    final coinLight =
        lerpDouble(breath, 1, stageProgress(d, 0, revealAt))! *
        (1 - stageProgress(d, revealAt, revealAt + 0.06)) *
        lerpDouble(1, 0.5, stageProgress(r, 0.1, 0.6))!;
    // The sonar of the wait: it leaves with the turn or the fall.
    final waiting =
        stageProgress(e, 0.6, 1) *
        (1 - stageProgress(d, 0, 0.12)) *
        (1 - stageProgress(r, 0, 0.12));
    final drift = Curves.easeOut.transform(stageProgress(r, 0.15, 0.6));
    final ringAppear =
        Curves.easeOut.transform(stageProgress(e, 0.2, 0.8)) * (1 - drift);
    final ringScale =
        lerpDouble(
          0.7,
          1,
          Curves.easeOut.transform(stageProgress(e, 0.2, 0.8)),
        )! +
        0.35 * drift;
    final ringOrbit =
        0.25 * e +
        m.wait +
        0.6 * Curves.easeOutCubic.transform(d) +
        0.3 * Curves.easeOutCubic.transform(r);
    final secondAppear = Curves.easeOut.transform(stageProgress(d, 0.5, 0.75));
    final secondOrbit = Curves.easeOutCubic.transform(stageProgress(d, 0.5, 1));

    Offset stageCenter(Size size) => Offset(size.width / 2, size.height * 0.46);

    final depixFace = RepaintBoundary(
      child: StageFace.asset(
        Asset.depix,
        size: coinSize,
        tint: brand,
        palette: palette,
      ),
    );
    final pixFace = RepaintBoundary(
      child: StageFace(
        shape: stagePixShape,
        size: coinSize,
        tint: brand,
        palette: palette,
        glyph: (color) => SvgPicture.asset(
          stagePixGlyph,
          width: coinSize * stagePixGlyphScale,
          height: coinSize * stagePixGlyphScale,
          colorMapper: TwoToneGlyphColors(color),
        ),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stage = stageCenter(Size(constraints.maxWidth, height));
            final token = stage + Offset(0, pose.lift);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                StagePaintLayer((canvas, size) {
                  effects(canvas)
                    ..glow(token, coinLight)
                    ..glow(
                      token,
                      stageProgress(d, revealAt - 0.02, revealAt + 0.12),
                    )
                    // The beam reaches past the top of the screen, so it
                    // shows no end: the list of the page starts there.
                    ..beam(
                      stage,
                      -reach,
                      Curves.easeOut.transform(stageProgress(d, 0.5, 0.8)),
                    )
                    ..floor(
                      stage,
                      lerpDouble(
                            0.6 *
                                Curves.easeOut.transform(
                                  stageProgress(e, 0.4, 0.9),
                                ),
                            1,
                            Curves.easeOut.transform(
                              stageProgress(d, 0.55, 0.85),
                            ),
                          )! *
                          lerpDouble(1, 0.7, stageProgress(r, 0.3, 0.9))!,
                    )
                    ..dots(
                      size,
                      lerpDouble(
                        0.5 * stageProgress(e, 0.4, 1),
                        1,
                        stageProgress(d, 0.55, 1),
                      )!,
                    )
                    ..shockwave(
                      token,
                      radius * 3.4,
                      stageProgress(m.wait, 0, 0.5),
                      0.35 * waiting,
                    )
                    ..ring(
                      token,
                      _waitRing,
                      StageLayer.back,
                      appear: ringAppear,
                      orbit: ringOrbit,
                      scale: ringScale,
                    )
                    ..ring(
                      token,
                      stageRings[0],
                      StageLayer.back,
                      appear: secondAppear,
                      orbit: secondOrbit,
                    );
                  _gather(effects(canvas), token, d);
                  _embers(effects(canvas), token, r);
                  if (d >= revealAt && d < 1) {
                    effects(canvas)
                      ..shockwave(
                        token,
                        reach,
                        stageProgress(d, revealAt, 0.9),
                        1,
                      )
                      ..shockwave(
                        token,
                        reach,
                        stageProgress(d, 0.5, 0.98),
                        0.45,
                      )
                      ..flash(token, stageProgress(d, revealAt, 0.6))
                      ..burst(token, d, start: revealAt, end: 1);
                  }
                }),
                Positioned(
                  left: token.dx - coinSize / 2,
                  top: token.dy - coinSize / 2,
                  child: Opacity(
                    opacity: pose.opacity,
                    child: Transform.scale(
                      scale: pose.scale,
                      child: StageToken(
                        shape: pose.showsPix
                            ? stagePixShape
                            : const CircleBorder(),
                        size: coinSize,
                        yaw: StageToken.faceYaw(pose.turn),
                        tint: brand,
                        base: palette.base,
                        // It turns past edge-on, so it turns around its
                        // middle.
                        centered: true,
                        // Both faces are built, so the Pix shows at once at
                        // edge-on.
                        face: IndexedStack(
                          index: pose.showsPix ? 1 : 0,
                          children: [depixFace, pixFace],
                        ),
                      ),
                    ),
                  ),
                ),
                StagePaintLayer((canvas, size) {
                  effects(canvas)
                    ..ring(
                      token,
                      _waitRing,
                      StageLayer.front,
                      appear: ringAppear,
                      orbit: ringOrbit,
                      scale: ringScale,
                    )
                    ..ring(
                      token,
                      stageRings[0],
                      StageLayer.front,
                      appear: secondAppear,
                      orbit: secondOrbit,
                    )
                    ..sparkles(token, d, delay: 0.04, span: 0.16);
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Particles of DePix drawn into the coin as it spins up.
  static void _gather(StageEffects effects, Offset token, double d) {
    for (final particle in stageParticles) {
      final p = stageProgress(d, particle.delay, revealAt);
      if (p <= 0 || p >= 1) continue;
      final distance =
          radius *
          lerpDouble(
            1 + 2.6 * particle.speed,
            0.9,
            Curves.easeInCubic.transform(p),
          )!;
      effects.drawParticle(
        token +
            Offset(math.cos(particle.angle), math.sin(particle.angle)) *
                distance,
        particle,
        scale: lerpDouble(0.6, 1.1, p)!,
        strength: math.sin(math.pi * p),
      );
    }
  }

  /// Embers that fall from the sides and the bottom of the coin, and fade.
  static void _embers(StageEffects effects, Offset token, double r) {
    for (final particle in stageParticles.take(18)) {
      final p = stageProgress(r, 0.15 + particle.delay * 2, 0.98);
      if (p <= 0 || p >= 1) continue;
      final angle = particle.angle / 2;
      final start =
          token +
          Offset(
            math.cos(angle) * radius * 0.85,
            math.sin(angle) * radius * 0.5,
          );
      effects.drawParticle(
        start +
            Offset(
              math.cos(angle) * radius * 0.3 * p,
              radius * 1.6 * particle.speed * Curves.easeIn.transform(p),
            ),
        particle,
        scale: 1 - 0.3 * p,
        strength: 0.8 * math.sin(math.pi * p),
      );
    }
  }

  /// Radius of the coin.
  static const double radius = coinSize / 2;
}

/// Drives a [PixSendScene] through the life of a send: the entrance of the
/// coin, the wait for the provider, and the outcome.
///
/// The state of the result screen owns it: it passes itself as the vsync,
/// keeps [still] in step with the system, plays [beats] with
/// [StageHaptics] on [delivered], shows it with [PixSendSceneView], and
/// disposes it.
class PixSendStage {
  PixSendStage({required TickerProvider vsync})
    : _entrance = AnimationController(
        vsync: vsync,
        duration: Motion.durationPixSendEntrance,
      ),
      _wait = AnimationController(
        vsync: vsync,
        duration: Motion.durationPixSendWait,
      ),
      _delivered = AnimationController(
        vsync: vsync,
        duration: Motion.durationPixDelivered,
      ),
      _returned = AnimationController(
        vsync: vsync,
        duration: Motion.durationPixReturned,
      );

  /// Whether the system asks for reduced motion: the scene then shows each
  /// state at once, and nothing loops.
  bool still = false;

  final AnimationController _entrance;
  final AnimationController _wait;
  final AnimationController _delivered;
  final AnimationController _returned;

  late final Listenable listenable = Listenable.merge([
    _entrance,
    _wait,
    _delivered,
    _returned,
  ]);

  /// The turn of a delivered Pix, for the haptics and the title.
  Animation<double> get delivered => _delivered;

  /// The haptics of a delivered Pix: a light one as the coin starts to
  /// spin, a heavy one as it becomes the Pix token, a light one as the
  /// token lands.
  static const List<StageBeat> beats = [
    (at: 0, play: HapticFeedback.lightImpact),
    (at: PixSendScene.revealAt, play: HapticFeedback.heavyImpact),
    (at: PixSendScene.landAt, play: HapticFeedback.lightImpact),
  ];

  PixSendMotion get motion => PixSendMotion(
    entrance: _entrance.value,
    wait: _wait.value,
    delivered: _delivered.value,
    returned: _returned.value,
  );

  /// Whether the scene tells that the Pix was delivered: the Pix token
  /// shows.
  bool get showsPix => _delivered.value >= PixSendScene.revealAt;

  /// The coin comes in. Completes once it is in place.
  Future<void> enter() async {
    if (still) {
      _entrance.value = 1;
      return;
    }
    await _entrance.forward();
  }

  /// The provider pays: the wait loops until [settle], [deliver] or
  /// [giveBack]. Under reduced motion, nothing loops.
  void wait() {
    if (still || _wait.isAnimating) return;
    _wait.repeat();
  }

  /// Nothing reads the status anymore: the wait ends its cycle and rests.
  void settle() {
    if (_wait.isAnimating) _wait.forward();
  }

  /// The Pix was delivered: the coin becomes the Pix token. Under reduced
  /// motion the token shows at once, with a light haptic. Completes once
  /// the scene rests.
  Future<void> deliver() async {
    _wait.stop();
    _entrance.value = 1;
    if (still) {
      _delivered.value = 1;
      HapticFeedback.lightImpact();
      return;
    }
    await _delivered.forward();
  }

  /// The Pix was not paid: the coin settles and sinks, with one light
  /// haptic.
  void giveBack() {
    _wait.stop();
    _entrance.value = 1;
    HapticFeedback.lightImpact();
    if (still) {
      _returned.value = 1;
    } else {
      _returned.forward();
    }
  }

  /// The scene at the rest of an outcome that came before the screen, as a
  /// payment opened from the history: no motion, no haptic.
  void restAt({required bool delivered}) {
    _entrance.value = 1;
    if (delivered) {
      _delivered.value = 1;
    } else {
      _returned.value = 1;
    }
  }

  void dispose() {
    _entrance.dispose();
    _wait.dispose();
    _delivered.dispose();
    _returned.dispose();
  }
}

/// The [PixSendScene] of [stage].
class PixSendSceneView extends StatelessWidget {
  const PixSendSceneView({super.key, required this.stage});

  final PixSendStage stage;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: stage.listenable,
    builder: (context, _) => PixSendScene(motion: stage.motion),
  );
}
