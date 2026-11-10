import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';

/// A token that turns from one face to another, on a stage in the colors
/// of its [StagePalette]: the moment of a change, such as a new wallet
/// level or a finished swap. Each face and its light take their own tint.
///
/// Up, the token lifts and spins faster and faster while particles gather
/// into it. The second face shows with a flash and a shockwave: particles
/// burst out, two rings fade in and orbit, and the token lands, with a few
/// sparkles, a beam of light, and ripples on the floor.
///
/// Down, the token turns once, slowly, and sinks a little. The outer ring
/// drifts away and fades, the light dims to the second tint, and embers
/// fall. No flash and no shockwave.
///
/// [animation] runs from 0 to 1. At 1 the scene rests and nothing loops,
/// so a screen with reduced motion sets it to 1.
///
/// Haptics mark the moments while [animation] runs forward:
/// - Up: a light impact as the spin starts ([spinAt]), a heavy one as the
///   second face shows ([upRevealAt]), and a light one as the token lands
///   ([landAt]).
/// - Down: one light impact as the second face shows ([downRevealAt]).
///
/// The system haptic setting applies to all of them.
class StageTurn extends StatefulWidget {
  const StageTurn({
    super.key,
    required this.animation,
    this.upward = true,
    this.shape = const CircleBorder(),
    required this.size,
    this.height = 280,
    required this.from,
    required this.to,
    required this.fromTint,
    required this.toTint,
  });

  final Animation<double> animation;

  /// Whether the change goes up: a spin up to a flash and a shockwave. Down
  /// is a slow turn.
  final bool upward;

  final OutlinedBorder shape;

  /// Width of the token.
  final double size;

  /// Height of the stage. The shockwave and the light reach past it.
  final double height;

  /// The faces before and after the turn, [size] wide. Both are built from
  /// the start, so the second face is ready when it shows.
  final Widget from;
  final Widget to;

  final Color fromTint;
  final Color toTint;

  /// Progress at which the token starts to spin up.
  static const double spinAt = 0.14;

  /// Progress at which the second face shows up.
  static const double upRevealAt = 0.5;

  /// Progress at which the token lands up.
  static const double landAt = 0.76;

  /// Progress at which the second face shows down.
  static const double downRevealAt = 0.44;

  @override
  State<StageTurn> createState() => _StageTurnState();
}

class _StageTurnState extends State<StageTurn> with StageHaptics {
  @override
  Animation<double> get stageAnimation => widget.animation;

  @override
  List<StageBeat> get stageBeats => widget.upward
      ? const [
          (at: StageTurn.spinAt, play: HapticFeedback.lightImpact),
          (at: StageTurn.upRevealAt, play: HapticFeedback.heavyImpact),
          (at: StageTurn.landAt, play: HapticFeedback.lightImpact),
        ]
      : const [(at: StageTurn.downRevealAt, play: HapticFeedback.lightImpact)];

  @override
  Widget build(BuildContext context) {
    final upward = widget.upward;
    final palette = StagePalette.of(context);
    // The shockwave crosses the whole screen.
    final reach = MediaQuery.sizeOf(context).longestSide;
    final size = widget.size;

    _StagePainter painter(StageLayer layer) => _StagePainter(
      animation: widget.animation,
      layer: layer,
      upward: upward,
      fromTint: widget.fromTint,
      toTint: widget.toTint,
      palette: palette,
      radius: size / 2,
      reach: reach,
    );

    // Each face paints once; only the token moves.
    final faces = [
      RepaintBoundary(child: widget.from),
      RepaintBoundary(child: widget.to),
    ];

    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = _StagePainter.centerOf(
              Size(constraints.maxWidth, widget.height),
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: painter(StageLayer.back)),
                  ),
                ),
                Positioned(
                  left: center.dx - size / 2,
                  top: center.dy - size / 2,
                  child: AnimatedBuilder(
                    animation: widget.animation,
                    builder: (context, _) {
                      final pose = _Pose.at(widget.animation.value, upward);
                      final second = pose.showsSecond(upward);
                      return Opacity(
                        opacity: pose.opacity,
                        child: Transform.translate(
                          offset: Offset(0, pose.lift),
                          child: Transform.scale(
                            scale: pose.scale,
                            child: StageToken(
                              shape: widget.shape,
                              size: size,
                              yaw: StageToken.faceYaw(pose.turn),
                              tint: second ? widget.toTint : widget.fromTint,
                              base: palette.base,
                              centered: true,
                              face: IndexedStack(
                                index: second ? 1 : 0,
                                children: faces,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: painter(StageLayer.front)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Yaw at which the token rests, turned to show its edge.
const _restYaw = 0.42;

/// Turn at which the token is edge-on and shows its second face: after a
/// turn and a quarter up, after a quarter turn down.
const _upReveal = 2.5 * math.pi;
const _downReveal = 0.5 * math.pi;

/// Where the token is at a time of the scene.
class _Pose {
  const _Pose({
    required this.turn,
    required this.lift,
    required this.scale,
    required this.opacity,
  });

  /// How far the token has turned, in radians.
  final double turn;

  /// Vertical offset from the center of the stage: up is negative.
  final double lift;

  final double scale;
  final double opacity;

  bool showsSecond(bool upward) => turn >= (upward ? _upReveal : _downReveal);

  factory _Pose.at(double t, bool upward) {
    final opacity = stageProgress(t, 0, 0.1);
    final grow = Curves.easeOutCubic.transform(stageProgress(t, 0, 0.16));
    if (upward) {
      const reveal = StageTurn.upRevealAt;
      // Faster and faster up to the reveal; then a snap past the rest,
      // and back.
      final turn = t < reveal
          ? lerpDouble(
              -_restYaw,
              _upReveal,
              Curves.easeInCubic.transform(
                stageProgress(t, StageTurn.spinAt, reveal),
              ),
            )!
          : lerpDouble(
              _upReveal,
              3 * math.pi + _restYaw,
              Curves.easeOutBack.transform(
                stageProgress(t, reveal, StageTurn.landAt),
              ),
            )!;
      final rise = stageProgress(t, StageTurn.spinAt, StageTurn.landAt);
      // A short swell as the second face shows.
      final swell = math.sin(math.pi * stageProgress(t, 0.46, 0.68));
      return _Pose(
        turn: turn,
        lift: -14 * math.sin(math.pi * rise),
        scale: lerpDouble(0.82, 1, grow)! * (1 + 0.08 * swell),
        opacity: opacity,
      );
    }
    // One even turn, edge-on halfway through, at the reveal.
    final p = stageProgress(t, 0.18, 0.7);
    final sink = Curves.easeInOutCubic.transform(stageProgress(t, 0.3, 0.8));
    return _Pose(
      turn: lerpDouble(
        -_restYaw,
        math.pi + _restYaw,
        (1 - math.cos(math.pi * p)) / 2,
      )!,
      lift: 10 * sink,
      scale: lerpDouble(0.9, 1, grow)! * (1 - 0.05 * sink),
      opacity: opacity,
    );
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter({
    required this.animation,
    required this.layer,
    required this.upward,
    required this.fromTint,
    required this.toTint,
    required this.palette,
    required this.radius,
    required this.reach,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final StageLayer layer;
  final bool upward;
  final Color fromTint;
  final Color toTint;
  final StagePalette palette;
  final double radius;

  /// Largest radius of the shockwave.
  final double reach;

  /// Center of the token at rest on a stage of [size].
  static Offset centerOf(Size size) =>
      Offset(size.width / 2, size.height * 0.46);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final stage = centerOf(size);
    // The token lifts and sinks: its light and its rings follow it, the
    // floor stays.
    final token = stage + Offset(0, _Pose.at(t, upward).lift);
    StageEffects effects(Color tint) => StageEffects(
      canvas,
      tint: tint,
      light: palette.highlight(tint),
      radius: radius,
    );
    if (upward) {
      _paintUp(effects(fromTint), effects(toTint), size, stage, token, t);
    } else {
      _paintDown(effects(fromTint), effects(toTint), size, stage, token, t);
    }
  }

  void _paintUp(
    StageEffects old,
    StageEffects fresh,
    Size size,
    Offset stage,
    Offset token,
    double t,
  ) {
    const reveal = StageTurn.upRevealAt;
    if (layer == StageLayer.back) {
      // The light of the first face grows with the spin, then gives way to
      // the light of the second.
      old.glow(
        token,
        stageProgress(t, 0, 0.16) *
            lerpDouble(0.6, 1, stageProgress(t, StageTurn.spinAt, reveal))! *
            (1 - stageProgress(t, reveal, reveal + 0.06)),
      );
      fresh
        ..glow(token, stageProgress(t, reveal - 0.02, reveal + 0.12))
        ..beam(
          stage,
          -reach,
          Curves.easeOut.transform(stageProgress(t, 0.56, 0.86)),
        )
        ..floor(stage, Curves.easeOut.transform(stageProgress(t, 0.62, 0.92)))
        ..dots(size, stageProgress(t, 0.62, 1));
      _gather(old, token, t);
      if (t >= reveal) {
        fresh
          ..shockwave(token, reach, stageProgress(t, reveal, 0.95), 1)
          ..shockwave(token, reach, stageProgress(t, 0.58, 1), 0.45)
          ..flash(token, stageProgress(t, reveal, 0.68))
          ..burst(token, t, start: reveal, end: 1);
      }
    }
    final appear = Curves.easeOut.transform(stageProgress(t, 0.56, 0.8));
    final orbit = Curves.easeOutCubic.transform(stageProgress(t, 0.56, 1));
    for (final ring in stageRings) {
      fresh.ring(token, ring, layer, appear: appear, orbit: orbit);
    }
    if (layer == StageLayer.front) {
      fresh.sparkles(token, t, delay: 0.08, span: 0.16);
    }
  }

  /// Particles in the first tint drawn into the token as it spins up.
  void _gather(StageEffects effects, Offset token, double t) {
    for (final particle in stageParticles) {
      final p = stageProgress(
        t,
        StageTurn.spinAt + particle.delay,
        StageTurn.upRevealAt,
      );
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

  void _paintDown(
    StageEffects old,
    StageEffects fresh,
    Size size,
    Offset stage,
    Offset token,
    double t,
  ) {
    if (layer == StageLayer.back) {
      // The light of the first face fades, and a dimmer light of the
      // second takes its place.
      old.glow(
        token,
        stageProgress(t, 0, 0.16) * (1 - stageProgress(t, 0.3, 0.6)),
      );
      fresh
        ..glow(token, 0.6 * stageProgress(t, 0.42, 0.75))
        ..floor(
          stage,
          0.7 * Curves.easeOut.transform(stageProgress(t, 0.6, 0.95)),
        )
        ..dots(size, 0.5 * stageProgress(t, 0.6, 1));
      _fall(old, token, t);
    }
    // The rings were there before: they show at once and orbit slowly. The
    // outer ring drifts away and fades; the inner one takes the light of
    // the second face.
    final shown = Curves.easeOut.transform(stageProgress(t, 0, 0.2));
    final scale = lerpDouble(0.7, 1, shown)!;
    final orbit = 0.5 * Curves.easeOutCubic.transform(t);
    final drift = Curves.easeOut.transform(stageProgress(t, 0.3, 0.62));
    final change = stageProgress(t, 0.4, 0.72);
    final [outer, inner] = stageRings;
    old
      ..ring(
        token,
        outer,
        layer,
        appear: shown * (1 - drift),
        orbit: orbit,
        scale: scale + 0.35 * drift,
      )
      ..ring(
        token,
        inner,
        layer,
        appear: shown * (1 - change),
        orbit: orbit,
        scale: scale,
      );
    fresh.ring(
      token,
      inner,
      layer,
      appear: shown * change,
      orbit: orbit,
      scale: scale,
    );
  }

  /// Embers in the first tint that fall from the sides and the bottom of
  /// the token, and fade.
  void _fall(StageEffects effects, Offset token, double t) {
    for (final particle in stageParticles.take(18)) {
      final p = stageProgress(t, 0.3 + particle.delay * 2, 0.98);
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

  @override
  bool shouldRepaint(_StagePainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.layer != layer ||
      oldDelegate.upward != upward ||
      oldDelegate.fromTint != fromTint ||
      oldDelegate.toTint != toTint ||
      oldDelegate.palette != palette ||
      oldDelegate.radius != radius ||
      oldDelegate.reach != reach;
}
