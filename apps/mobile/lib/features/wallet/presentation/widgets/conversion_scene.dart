import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_face.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The end of a conversion between chains, on the stage of the
/// celebrations, in the language of the swap page of the onboarding: two
/// coins trade places on one orbit, inside two crossing rings.
///
/// The coin of [fromAsset] starts in front and the coin of [toAsset]
/// behind it. They swing around each other, half a turn, and the light
/// flares as they cross. The coin of [toAsset] lands in front with a flash
/// and a shockwave; the coin of [fromAsset] rests behind it, dimmed. Then
/// the scene stays still: nothing loops.
///
/// [animation] runs from 0 to 1 over [Motion.durationConversion]. At 1 the
/// scene rests, so under reduced motion it is set to 1 and nothing plays.
///
/// Two haptics mark the moments while [animation] runs forward: a light
/// impact as the coins set off, and a heavy one as the received coin lands
/// ([landAt]). The system haptic setting applies to both.
class ConversionScene extends StatefulWidget {
  const ConversionScene({
    super.key,
    required this.fromAsset,
    required this.toAsset,
    required this.animation,
  });

  final Asset fromAsset;
  final Asset toAsset;
  final Animation<double> animation;

  /// Height of the stage. The shockwave reaches past it.
  static const double height = 300;

  /// Width of a coin in front.
  static const double coinSize = 120;

  /// Progress at which the received coin lands in front: the flash, the
  /// shockwave, and the heavy impact.
  static const double landAt = 0.66;

  @override
  State<ConversionScene> createState() => _ConversionSceneState();
}

class _ConversionSceneState extends State<ConversionScene> with StageHaptics {
  @override
  Animation<double> get stageAnimation => widget.animation;

  @override
  List<StageBeat> get stageBeats => const [
    (at: 0, play: HapticFeedback.lightImpact),
    (at: ConversionScene.landAt, play: HapticFeedback.heavyImpact),
  ];

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final palette = StagePalette.of(context);
    // The shockwave crosses the whole screen.
    final reach = MediaQuery.sizeOf(context).longestSide;
    const coinSize = ConversionScene.coinSize;
    // The faces are the same on every frame, so each paints once and only
    // its transform changes.
    Widget face(Asset asset) => RepaintBoundary(
      child: StageFace.asset(
        asset,
        size: coinSize,
        tint: brand,
        palette: palette,
      ),
    );
    final fromFace = face(widget.fromAsset);
    final toFace = face(widget.toAsset);

    return ExcludeSemantics(
      child: SizedBox(
        height: ConversionScene.height,
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: widget.animation,
            builder: (context, _) => Stack(
              clipBehavior: Clip.none,
              children: _layers(
                t: widget.animation.value,
                size: Size(constraints.maxWidth, ConversionScene.height),
                brand: brand,
                palette: palette,
                reach: reach,
                fromFace: fromFace,
                toFace: toFace,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _layers({
    required double t,
    required Size size,
    required Color brand,
    required StagePalette palette,
    required double reach,
    required Widget fromFace,
    required Widget toFace,
  }) {
    const coinSize = ConversionScene.coinSize;
    const radius = coinSize / 2;
    const landAt = ConversionScene.landAt;
    final center = Offset(size.width / 2, size.height * 0.46);
    final rx = math.min(size.width * 0.31, 120.0);
    final ry = rx * 0.3;
    const tilt = -0.08;

    // The coins grow out of the center onto their orbit.
    final grow = Curves.easeOutBack.transform(stageProgress(t, 0, 0.4));
    // The sent coin starts in front, a little to the right. Half a turn
    // later the received coin is there, and the sent one behind it.
    const start = math.pi / 2 - 0.5;
    final swap = Curves.easeInOutCubic.transform(
      stageProgress(t, 0.18, landAt),
    );
    final fromAngle = start + swap * math.pi;
    final toAngle = fromAngle + math.pi;
    Offset placeOf(double angle) =>
        center + stageOrbitPoint(angle, rx, ry, tilt) * grow;
    final toAt = placeOf(toAngle);
    // The light flares as the coins cross, halfway through the turn.
    final flare = math.sin(math.pi * stageProgress(t, 0.27, 0.57));
    // The received coin swells once as it lands.
    final land = math.sin(math.pi * stageProgress(t, landAt, 0.86));

    final rings = [
      StageRing(
        width: rx * 1.15 / radius,
        height: rx * 0.42 / radius,
        tilt: 0.42,
        turns: 1.1,
        phase: 0,
      ),
      StageRing(
        width: rx * 1.15 / radius,
        height: rx * 0.42 / radius,
        tilt: -0.42,
        turns: -1.1,
        phase: math.pi,
      ),
    ];
    final ringAppear = Curves.easeOut.transform(stageProgress(t, 0.05, 0.5));
    final ringOrbit = Curves.easeOutCubic.transform(stageProgress(t, 0.05, 1));
    StageEffects effects(Canvas canvas) => StageEffects(
      canvas,
      tint: brand,
      light: palette.highlight(brand),
      radius: radius,
    );
    void paintRings(StageEffects effects, StageLayer layer) {
      for (final ring in rings) {
        effects.ring(
          center,
          ring,
          layer,
          appear: ringAppear,
          orbit: ringOrbit,
          scale: lerpDouble(0.7, 1, grow)!,
        );
      }
    }

    Widget coin(Key key, double angle, Widget face, {double swell = 0}) {
      final near = stageNearness(angle);
      return StagePlaced(
        key: key,
        at: placeOf(angle),
        size: coinSize,
        scale:
            lerpDouble(0.74, 1, near)! *
            lerpDouble(0.6, 1, grow)! *
            (1 + 0.08 * swell),
        // The coin behind dims, so the one in front leads.
        opacity: stageProgress(t, 0, 0.15) * lerpDouble(0.5, 1, near)!,
        child: StageToken(
          size: coinSize,
          yaw: -0.3 * math.cos(angle),
          tint: brand,
          base: palette.base,
          face: face,
        ),
      );
    }

    // Keyed, so a coin keeps its element, and its decoded face, when the
    // two change places in the stack.
    final coins = [
      (
        angle: fromAngle,
        widget: coin(const ValueKey('from'), fromAngle, fromFace),
      ),
      (
        angle: toAngle,
        widget: coin(const ValueKey('to'), toAngle, toFace, swell: land),
      ),
    ]..sort((a, b) => math.sin(a.angle).compareTo(math.sin(b.angle)));

    return [
      StagePaintLayer((canvas, size) {
        final stage = effects(canvas)
          ..glow(center, (0.5 + 0.5 * flare) * ringAppear)
          ..dots(size, 0.6 * stageProgress(t, 0.4, 1));
        // A flash draws even at its start, so it waits for the landing.
        if (t >= landAt) {
          stage
            ..glow(toAt, 0.7 * stageProgress(t, landAt, 0.82))
            ..shockwave(toAt, reach, stageProgress(t, landAt, 1), 0.7)
            ..shockwave(toAt, reach, stageProgress(t, landAt + 0.06, 1), 0.3)
            ..flash(toAt, stageProgress(t, landAt, 0.84));
        }
        paintRings(stage, StageLayer.back);
      }),
      for (final c in coins) c.widget,
      StagePaintLayer((canvas, size) {
        final stage = effects(canvas);
        paintRings(stage, StageLayer.front);
        stage.sparkles(center, t);
      }),
    ];
  }
}
