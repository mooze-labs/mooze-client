import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_face.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The entrance of a received payment, on the stage of the confirmation
/// screen, in the colors of its [StagePalette].
///
/// A flash and a pink shockwave leave the center and cross the screen. The
/// coin of the received asset grows out of the flash, turned to show its
/// ridged edge. Two rings fade in around it and orbit at different speeds,
/// with particles and a few sparkles, then slow down and rest. The scene
/// then stays still: nothing loops.
///
/// [animation] runs from 0 to 1 over [Motion.durationReceive]. At 1 the
/// scene rests, so a screen with reduced motion, or one shown again, sets
/// it to 1 and nothing plays.
///
/// Three haptics mark the moments while [animation] runs forward:
/// 1. A heavy impact when it starts: the payment arrived.
/// 2. A medium impact as the shockwave expands ([shockwaveImpactAt]).
/// 3. A light impact when the coin lands ([coinImpactAt]).
///
/// The system haptic setting applies to all three.
class ReceiveCelebration extends StatefulWidget {
  const ReceiveCelebration({
    super.key,
    required this.asset,
    required this.animation,
  });

  final Asset asset;
  final Animation<double> animation;

  /// Height of the stage. The shockwave and the light beam reach past it.
  static const double height = 300;

  /// Diameter of the coin.
  static const double coinSize = 132;

  /// Progress at which the medium impact plays, as the shockwave grows.
  static const double shockwaveImpactAt = 0.12;

  /// Progress at which the light impact plays, as the coin lands.
  static const double coinImpactAt = 0.42;

  @override
  State<ReceiveCelebration> createState() => _ReceiveCelebrationState();
}

class _ReceiveCelebrationState extends State<ReceiveCelebration>
    with StageHaptics {
  @override
  Animation<double> get stageAnimation => widget.animation;

  @override
  List<StageBeat> get stageBeats => const [
    (at: 0, play: HapticFeedback.heavyImpact),
    (
      at: ReceiveCelebration.shockwaveImpactAt,
      play: HapticFeedback.mediumImpact,
    ),
    (at: ReceiveCelebration.coinImpactAt, play: HapticFeedback.lightImpact),
  ];

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final palette = StagePalette.of(context);
    // The shockwave crosses the whole screen.
    final reach = MediaQuery.sizeOf(context).longestSide;
    const coinSize = ReceiveCelebration.coinSize;

    _StagePainter painter(StageLayer layer) => _StagePainter(
      animation: widget.animation,
      layer: layer,
      brand: brand,
      light: palette.highlight(brand),
      coinRadius: coinSize / 2,
      reach: reach,
    );

    return ExcludeSemantics(
      child: SizedBox(
        height: ReceiveCelebration.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = _StagePainter.centerOf(
              Size(constraints.maxWidth, ReceiveCelebration.height),
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
                  left: center.dx - coinSize / 2,
                  top: center.dy - coinSize / 2,
                  child: AnimatedBuilder(
                    animation: widget.animation,
                    builder: (context, child) {
                      final t = widget.animation.value;
                      final grow = stageProgress(t, 0.20, 0.48);
                      final turn = Curves.easeOutCubic.transform(
                        stageProgress(t, 0.20, 0.72),
                      );
                      return Opacity(
                        opacity: stageProgress(t, 0.20, 0.30),
                        child: Transform.scale(
                          scale: lerpDouble(
                            0.3,
                            1,
                            Curves.easeOutBack.transform(grow),
                          )!,
                          child: StageToken(
                            size: coinSize,
                            yaw: lerpDouble(1.3, 0.42, turn)!,
                            tint: brand,
                            base: palette.base,
                            face: child!,
                          ),
                        ),
                      );
                    },
                    // The face is the same on every frame, so it paints
                    // once and only its transform changes.
                    child: RepaintBoundary(
                      child: StageFace.asset(
                        widget.asset,
                        size: coinSize,
                        tint: brand,
                        palette: palette,
                      ),
                    ),
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

class _StagePainter extends CustomPainter {
  _StagePainter({
    required this.animation,
    required this.layer,
    required this.brand,
    required this.light,
    required this.coinRadius,
    required this.reach,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final StageLayer layer;
  final Color brand;
  final Color light;
  final double coinRadius;

  /// Largest radius of the shockwave.
  final double reach;

  /// Center of the coin on a stage of [size].
  static Offset centerOf(Size size) =>
      Offset(size.width / 2, size.height * 0.44);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final center = centerOf(size);
    final effects = StageEffects(
      canvas,
      tint: brand,
      light: light,
      radius: coinRadius,
    );
    if (layer == StageLayer.back) {
      // The light behind the coin rises with it and stays, then the beam,
      // the ripples on the floor, and the dots settle.
      effects
        ..glow(center, stageProgress(t, 0.2, 0.5))
        ..beam(
          center,
          -reach,
          Curves.easeOut.transform(stageProgress(t, 0.3, 0.7)),
        )
        ..floor(center, Curves.easeOut.transform(stageProgress(t, 0.45, 0.85)))
        ..dots(size, stageProgress(t, 0.5, 1))
        ..shockwave(center, reach, stageProgress(t, 0.03, 0.6), 1)
        ..shockwave(center, reach, stageProgress(t, 0.14, 0.72), 0.45)
        ..flash(center, stageProgress(t, 0, 0.22))
        ..burst(center, t, start: 0.04, end: 0.95);
    }
    final appear = Curves.easeOut.transform(stageProgress(t, 0.34, 0.62));
    final orbit = Curves.easeOutCubic.transform(stageProgress(t, 0.34, 1));
    for (final ring in stageRings) {
      effects.ring(center, ring, layer, appear: appear, orbit: orbit);
    }
    if (layer == StageLayer.front) effects.sparkles(center, t);
  }

  @override
  bool shouldRepaint(_StagePainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.layer != layer ||
      oldDelegate.brand != brand ||
      oldDelegate.light != light ||
      oldDelegate.coinRadius != coinRadius ||
      oldDelegate.reach != reach;
}
