import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Where the closing scene is in its motion.
@immutable
class ClosingMotion {
  const ClosingMotion({
    this.spin = 0,
    this.departures = const {},
    this.farewell = 0,
  });

  /// A slow cycle, from 0 to 1, while the wallet is deleted: the coins
  /// orbit, the ring turns, and the light breathes. It stops once the
  /// wallet is deleted, or the delete fails, and stays where it stopped.
  final double spin;

  /// How far each asset coin has flown out of the orbit, from 0, on the
  /// orbit, to 1, gone.
  final Map<Asset, double> departures;

  /// The farewell once the wallet is deleted, from 0 to 1, over
  /// `Motion.durationFarewell`.
  final double farewell;
}

/// The art of the screen that deletes a wallet: the opening of a wallet,
/// played backward and put to rest.
///
/// It starts where the opening ended: the Mooze coin at the center, the
/// orbit ring, and the coin of each asset on the orbit. While the wallet
/// is deleted, the coins leave the orbit one after another, the way they
/// came in. Once it is deleted, the farewell plays. It is a loss, so it is
/// quiet: no flash and no shockwave.
///
/// | Farewell     | What happens                                         |
/// |--------------|------------------------------------------------------|
/// | 0 → 0.42     | The ring drifts away: it grows by a third and fades. |
/// | 0.05 → 0.5   | The dots of the stage fade.                          |
/// | 0.12 → 0.38  | The Mooze coin starts one half turn, faster and      |
/// |              | faster, from wherever its sway stopped.              |
/// | **0.38**     | **Edge-on**: the peak. A medium haptic.              |
/// | 0.38 → 0.72  | The turn slows to rest on the same face.             |
/// | 0.2 → 0.75   | The light dims to a faint glow.                      |
/// | 0.3 → 0.8    | The coin sinks a little and shrinks by 5%.           |
/// | **0.8**      | **Land**: a light haptic.                            |
/// | 0.3 → 0.98   | Embers fall from the lower edge of the coin.         |
/// | 0.6 → 0.95   | A faint floor appears under the coin.                |
///
/// At 1 the scene rests: the Mooze coin alone, dimly lit, on its floor.
///
/// It is decorative: the caption of the screen tells the step.
class ClosingScene extends StatelessWidget {
  const ClosingScene({super.key, required this.motion});

  final ClosingMotion motion;

  /// Farewell at which the Mooze coin is edge-on: the peak of the scene.
  static const double edgeOnAt = 0.38;

  /// Farewell at which the Mooze coin has sunk to rest.
  static const double landAt = 0.8;

  /// Farewell after which the caption tells that the wallet is deleted.
  static const double revealAt = 0.6;

  static const _moozeGlyph = 'assets/images/onboarding/mooze_m.svg';

  /// Yaw at which the Mooze coin rests after its turn.
  static const _restYaw = 0.3;

  /// Where the Mooze coin is in [motion]: its [turn], before it is folded
  /// into a yaw, and how far it has [sink], from 0 to 1.
  ///
  /// The turn speeds up to edge-on and slows down after it, in two
  /// halves. Edge-on falls at [edgeOnAt] by construction, wherever the
  /// sway of the coin stopped, so the haptic of the peak matches it.
  @visibleForTesting
  static ({double turn, double sink}) coreAt(ClosingMotion motion) {
    final sway = 0.3 + 0.18 * math.sin(4 * math.pi * motion.spin);
    final f = motion.farewell;
    final turn = f < edgeOnAt
        ? lerpDouble(
            sway,
            math.pi / 2,
            Curves.easeInSine.transform(stageProgress(f, 0.12, edgeOnAt)),
          )!
        : lerpDouble(
            math.pi / 2,
            math.pi + _restYaw,
            Curves.easeOutSine.transform(stageProgress(f, edgeOnAt, 0.72)),
          )!;
    final sink = Curves.easeInOutCubic.transform(stageProgress(f, 0.3, landAt));
    return (turn: turn, sink: sink);
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final palette = StagePalette.of(context);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The same stage as the opening of the wallet.
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
          final f = motion.farewell;

          final core = coreAt(motion);
          // The ring, the light, and the floor follow the coin as it sinks.
          final token = center + Offset(0, coreSize * 0.07 * core.sink);

          final gone =
              Asset.values.fold(
                0.0,
                (sum, asset) => sum + (motion.departures[asset] ?? 0),
              ) /
              Asset.values.length;
          // The light breathes while the wallet is deleted, and dims a
          // little with every coin that leaves.
          final waiting = 0.6 + 0.15 * math.sin(3 * cycle) - 0.15 * gone;
          final glow = lerpDouble(
            waiting,
            0.28,
            Curves.easeInOut.transform(stageProgress(f, 0.2, 0.75)),
          )!;
          final drift = Curves.easeOut.transform(stageProgress(f, 0, 0.42));
          final ringAppear = 1 - drift;
          final ringScale = 1 + 0.35 * drift;
          // The ring keeps turning as it drifts away, slower and slower.
          final ringOrbit = motion.spin + 0.15 * drift;

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
                departure: motion.departures[asset] ?? 0,
              ),
          ]..sort((a, b) => math.sin(a.angle).compareTo(math.sin(b.angle)));
          Widget coin(({Asset asset, double angle, double departure}) c) {
            final near = stageNearness(c.angle);
            // Out of the orbit, the way the coin came in: it draws back a
            // little, then leaves faster and faster.
            final travel = lerpDouble(
              1,
              2.4,
              Curves.easeInBack.transform(c.departure),
            )!;
            return StagePlaced(
              at: center + stageOrbitPoint(c.angle, rx, ry, tilt) * travel,
              size: coinSize,
              scale: lerpDouble(0.7, 1, near)!,
              opacity:
                  (1 - stageProgress(c.departure, 0.6, 1)) *
                  lerpDouble(0.55, 1, near)!,
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
                final stage = effects(canvas)
                  ..glow(token, glow)
                  ..dots(size, 0.6 * (1 - stageProgress(f, 0.05, 0.5)))
                  ..floor(
                    token,
                    0.5 * Curves.easeOut.transform(stageProgress(f, 0.6, 0.95)),
                  )
                  ..ring(
                    token,
                    ring,
                    StageLayer.back,
                    appear: ringAppear,
                    orbit: ringOrbit,
                    scale: ringScale,
                  );
                _fall(stage, token, coreSize / 2, f);
              }),
              for (final c in coins)
                if (c.departure < 1 && math.sin(c.angle) < 0) coin(c),
              StagePlaced(
                at: token,
                size: coreSize,
                scale: 1 - 0.05 * core.sink,
                child: GlyphToken(
                  glyphPath: _moozeGlyph,
                  size: coreSize,
                  yaw: StageToken.faceYaw(core.turn),
                  tint: brand,
                  palette: palette,
                  glyphScale: 0.5,
                  // It turns past edge-on, so it turns around its middle.
                  centered: true,
                ),
              ),
              StagePaintLayer((canvas, size) {
                effects(canvas).ring(
                  token,
                  ring,
                  StageLayer.front,
                  appear: ringAppear,
                  orbit: ringOrbit,
                  scale: ringScale,
                );
              }),
              for (final c in coins)
                if (c.departure < 1 && math.sin(c.angle) >= 0) coin(c),
            ],
          );
        },
      ),
    );
  }

  /// Embers that fall from the sides and the bottom of the coin of
  /// [radius] at [token], and fade, as the farewell [f] runs.
  static void _fall(
    StageEffects effects,
    Offset token,
    double radius,
    double f,
  ) {
    for (final particle in stageParticles.take(18)) {
      final p = stageProgress(f, 0.3 + particle.delay * 2, 0.98);
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
}
