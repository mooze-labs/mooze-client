import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Where the opening scene is in its motion.
@immutable
class OpeningMotion {
  const OpeningMotion({
    this.spin = 0,
    this.ring = 0,
    this.arrivals = const {},
    this.finale = 0,
  });

  /// A slow cycle, from 0 to 1, while the wallet opens: the coins orbit,
  /// the ring turns, and the light breathes. It stops once the wallet is
  /// open, or fails.
  final double spin;

  /// The orbit ring fading in, from 0 to 1, once the wallet connects.
  final double ring;

  /// How far each asset coin has flown into the orbit, from 0 to 1. A coin
  /// arrives when the chain of its asset has synced.
  final Map<Asset, double> arrivals;

  /// The burst once everything is ready, from 0 to 1.
  final double finale;
}

/// The art of the screen that opens a wallet: the Mooze coin at the
/// center, an orbit ring, and the coins of the assets flying into the
/// orbit, in the brand pink and the colors of the [StagePalette].
///
/// It is decorative: the caption of the screen tells the step.
class OpeningScene extends StatelessWidget {
  const OpeningScene({super.key, required this.motion});

  final OpeningMotion motion;

  static const _moozeGlyph = 'assets/images/onboarding/mooze_m.svg';

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final palette = StagePalette.of(context);
    final reach = MediaQuery.sizeOf(context).longestSide;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final s = size.shortestSide;
          final center = size.center(Offset.zero);
          final coreSize = s * 0.4;
          final coinSize = s * 0.21;
          final rx = math.min(size.width * 0.4, s * 0.66);
          final ry = rx * 0.3;
          const tilt = -0.16;
          final ring = StageRing(
            width: rx / (coreSize / 2),
            height: ry / (coreSize / 2),
            tilt: tilt,
            turns: 1,
            phase: 1,
          );
          final cycle = 2 * math.pi * motion.spin;
          final breath = math.sin(3 * cycle);
          final f = motion.finale;
          final ringAppear = Curves.easeOut.transform(motion.ring);

          StageEffects effects(Canvas canvas) => StageEffects(
            canvas,
            tint: brand,
            light: palette.highlight(brand),
            radius: coreSize / 2,
          );

          final coins = [
            for (final (k, asset) in Asset.values.indexed)
              (
                asset: asset,
                angle: math.pi / 4 + k * math.pi / 2 + cycle,
                arrival: motion.arrivals[asset] ?? 0,
              ),
          ]..sort((a, b) => math.sin(a.angle).compareTo(math.sin(b.angle)));
          Widget coin(({Asset asset, double angle, double arrival}) c) {
            final near = stageNearness(c.angle);
            // From outside the orbit into it.
            final travel = lerpDouble(
              2.4,
              1,
              Curves.easeOutBack.transform(c.arrival),
            )!;
            return StagePlaced(
              at: center + stageOrbitPoint(c.angle, rx, ry, tilt) * travel,
              size: coinSize,
              scale: lerpDouble(0.7, 1, near)!,
              opacity:
                  stageProgress(c.arrival, 0, 0.4) * lerpDouble(0.55, 1, near)!,
              child: AssetCoin(
                asset: c.asset,
                size: coinSize,
                yaw: -0.55 * math.cos(c.angle),
                tint: brand,
                palette: palette,
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              StagePaintLayer((canvas, size) {
                effects(canvas)
                  ..glow(
                    center,
                    math.min(
                      1,
                      0.6 + 0.15 * breath + 0.4 * math.sin(math.pi * f),
                    ),
                  )
                  ..dots(size, 0.6)
                  ..ring(
                    center,
                    ring,
                    StageLayer.back,
                    appear: ringAppear,
                    orbit: motion.spin,
                  );
                if (f > 0 && f < 1) {
                  effects(canvas)
                    ..shockwave(center, reach, stageProgress(f, 0, 0.9), 1)
                    ..flash(center, stageProgress(f, 0, 0.6))
                    ..burst(center, f, start: 0, end: 1);
                }
              }),
              for (final c in coins)
                if (c.arrival > 0 && math.sin(c.angle) < 0) coin(c),
              StagePlaced(
                at: center,
                size: coreSize,
                scale: 1 + 0.06 * math.sin(math.pi * f),
                child: GlyphToken(
                  glyphPath: _moozeGlyph,
                  size: coreSize,
                  yaw: 0.3 + 0.18 * math.sin(2 * cycle),
                  tint: brand,
                  palette: palette,
                  glyphScale: 0.5,
                ),
              ),
              StagePaintLayer((canvas, size) {
                effects(canvas)
                  ..ring(
                    center,
                    ring,
                    StageLayer.front,
                    appear: ringAppear,
                    orbit: motion.spin,
                  )
                  ..sparkles(center, lerpDouble(0.4, 1, f)!);
              }),
              for (final c in coins)
                if (c.arrival > 0 && math.sin(c.angle) >= 0) coin(c),
            ],
          );
        },
      ),
    );
  }
}
