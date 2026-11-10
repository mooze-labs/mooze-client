import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/setup/data/onboarding/onboarding_data.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Where an onboarding scene is in its motion.
@immutable
class SceneMotion {
  const SceneMotion({this.time = 1, this.offset = 0});

  /// The motion of a page shown before, or under reduced motion: at rest.
  static const rest = SceneMotion();

  /// Time since the page first showed, from 0 to 1 over
  /// [Motion.durationAmbient] forward and back. The scene enters first,
  /// over [Motion.durationOnboardingScene], then drifts. At 1 it rests.
  final double time;

  /// Where the page is from the center of the screen: 0 centered, -1 one
  /// page to the left, 1 one page to the right. The art turns with it, so
  /// it follows the finger.
  final double offset;

  /// The entrance, from 0 to 1.
  double get entrance => stageProgress(
    time,
    0,
    Motion.durationOnboardingScene.inMicroseconds /
        (Motion.durationAmbient * 2).inMicroseconds,
  );

  /// A slow sway that rises and falls back to 0.
  double get drift => math.sin(math.pi * time);
}

/// The art of an onboarding page, in the brand pink and the colors of the
/// [StagePalette], so it matches the confirmation of a received payment.
/// It is decorative: screen readers skip it.
class OnboardingSceneView extends StatelessWidget {
  const OnboardingSceneView({
    super.key,
    required this.scene,
    required this.motion,
  });

  final OnboardingScene scene;
  final SceneMotion motion;

  @override
  Widget build(BuildContext context) {
    final look = _Look(
      brand: context.colors.primaryColor,
      palette: StagePalette.of(context),
      ink: context.colors.textPrimary,
      muted: context.colors.textSecondary,
      label: context.textTheme.labelSmall ?? const TextStyle(),
    );
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return SizedBox.fromSize(
            size: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: switch (scene) {
                OnboardingScene.wallet => _walletScene(look, size, motion),
                OnboardingScene.pix => _pixScene(look, size, motion),
                OnboardingScene.swap => _swapScene(look, size, motion),
                OnboardingScene.security => _securityScene(look, size, motion),
              },
            ),
          );
        },
      ),
    );
  }
}

/// The colors of the scenes.
class _Look {
  const _Look({
    required this.brand,
    required this.palette,
    required this.ink,
    required this.muted,
    required this.label,
  });

  final Color brand;
  final StagePalette palette;

  /// Text and lines on the page.
  final Color ink;
  final Color muted;

  /// The style of the numbers of the recovery words.
  final TextStyle label;

  StageEffects effects(Canvas canvas, double radius) => StageEffects(
    canvas,
    tint: brand,
    light: palette.highlight(brand),
    radius: radius,
  );

  /// The coin of [asset], [size] wide, turned by [yaw].
  Widget coin(Asset asset, double size, double yaw) => AssetCoin(
    asset: asset,
    size: size,
    yaw: yaw,
    tint: brand,
    palette: palette,
  );

  /// A token in [shape] with the two-tone glyph of [glyphPath].
  Widget token(
    String glyphPath,
    double size,
    double yaw, {
    OutlinedBorder shape = const CircleBorder(),
    double glyphScale = 0.48,
  }) => GlyphToken(
    glyphPath: glyphPath,
    size: size,
    yaw: yaw,
    tint: brand,
    palette: palette,
    shape: shape,
    glyphScale: glyphScale,
  );
}

const _moozeGlyph = 'assets/images/onboarding/mooze_m.svg';
const _pixGlyph = 'assets/icons/menu/navigation/pix.svg';
const _lockGlyph = 'assets/images/onboarding/vault_lock.svg';

/// The Pix token: a diamond, like the Pix symbol on its face.
const _diamond = StarBorder.polygon(sides: 4, pointRounding: 0.32);

/// The vault: a hexagon, like the medals of the levels.
const _hexagon = StarBorder.polygon(sides: 6, pointRounding: 0.24);

// ── 1. Wallet: the four asset coins orbit the Mooze coin ───────────────────

List<Widget> _walletScene(_Look look, Size size, SceneMotion motion) {
  final s = size.shortestSide;
  final center = size.center(Offset.zero);
  final e = motion.entrance;
  final coreSize = s * 0.36;
  final coinSize = s * 0.21;
  final rx = math.min(size.width * 0.4, s * 0.66);
  final ry = rx * 0.3;
  const tilt = -0.16;
  final ring = StageRing(
    width: rx / (coreSize / 2),
    height: ry / (coreSize / 2),
    tilt: tilt,
    turns: 0.6,
    phase: 1,
  );
  // The coins spiral out of the Mooze coin to their orbit.
  final spread = Curves.easeOutBack.transform(stageProgress(e, 0.2, 0.85));
  final spiral =
      math.pi * (1 - Curves.easeOutCubic.transform(stageProgress(e, 0.2, 1)));
  final turn =
      math.pi / 4 - spiral + 0.35 * motion.drift + motion.offset * math.pi / 2;
  final ringAppear = Curves.easeOut.transform(stageProgress(e, 0.2, 0.7));
  final ringOrbit = 0.5 * e + 0.2 * motion.drift + 0.25 * motion.offset;

  final coins = [
    for (final (k, asset) in Asset.values.indexed)
      (asset: asset, angle: turn + k * math.pi / 2, k: k),
  ]..sort((a, b) => math.sin(a.angle).compareTo(math.sin(b.angle)));
  Widget coin(({Asset asset, double angle, int k}) c) {
    final near = stageNearness(c.angle);
    return StagePlaced(
      at: center + stageOrbitPoint(c.angle, rx, ry, tilt) * spread,
      size: coinSize,
      scale: lerpDouble(0.7, 1, near)!,
      opacity:
          stageProgress(e, 0.1 + 0.08 * c.k, 0.35 + 0.08 * c.k) *
          lerpDouble(0.55, 1, near)!,
      child: look.coin(c.asset, coinSize, -0.55 * math.cos(c.angle)),
    );
  }

  return [
    StagePaintLayer((canvas, size) {
      look.effects(canvas, coreSize / 2)
        ..glow(center, stageProgress(e, 0, 0.5))
        ..dots(size, 0.6 * stageProgress(e, 0.4, 1))
        ..ring(
          center,
          ring,
          StageLayer.back,
          appear: ringAppear,
          orbit: ringOrbit,
          scale: spread,
        );
    }),
    for (final c in coins)
      if (math.sin(c.angle) < 0) coin(c),
    StagePlaced(
      at: center,
      size: coreSize,
      scale: lerpDouble(
        0.6,
        1,
        Curves.easeOutBack.transform(stageProgress(e, 0, 0.5)),
      )!,
      opacity: stageProgress(e, 0, 0.25),
      child: look.token(
        _moozeGlyph,
        coreSize,
        0.3 + 0.25 * motion.drift + 0.6 * motion.offset,
        glyphScale: 0.5,
      ),
    ),
    StagePaintLayer((canvas, size) {
      look
          .effects(canvas, coreSize / 2)
          .ring(
            center,
            ring,
            StageLayer.front,
            appear: ringAppear,
            orbit: ringOrbit,
            scale: spread,
          );
    }),
    for (final c in coins)
      if (math.sin(c.angle) >= 0) coin(c),
  ];
}

// ── 2. Pix: a beam carries a Pix payment to a Bitcoin coin ────────────────

List<Widget> _pixScene(_Look look, Size size, SceneMotion motion) {
  final s = size.shortestSide;
  final center = size.center(Offset.zero);
  final e = motion.entrance;
  final tokenSize = s * 0.32;
  final reach = math.min(size.width * 0.26, size.height * 0.3);
  const slope = 0.42;
  final along = Offset(math.cos(slope), math.sin(slope));
  // The two tokens drift apart with the finger.
  final pixAt = center - along * reach + Offset(motion.offset * 18, 0);
  final coinAt = center + along * reach - Offset(motion.offset * 18, 0);
  final beamFrom = pixAt + along * tokenSize * 0.4;
  final beamTo = coinAt - along * tokenSize * 0.4;
  // The beam reaches the coin, then the coin turns up in a flash.
  final beam = Curves.easeInOutCubic.transform(stageProgress(e, 0.15, 0.55));
  final arrive = stageProgress(e, 0.5, 0.95);

  return [
    StagePaintLayer((canvas, size) {
      final effects = look.effects(canvas, tokenSize / 2)
        ..glow(pixAt, 0.7 * stageProgress(e, 0, 0.4))
        ..glow(coinAt, stageProgress(e, 0.5, 0.8))
        ..dots(size, 0.6 * stageProgress(e, 0.4, 1));
      if (beam > 0) {
        final end = Offset.lerp(beamFrom, beamTo, beam)!;
        canvas
          ..drawLine(
            beamFrom,
            end,
            Paint()
              ..strokeWidth = 10
              ..strokeCap = StrokeCap.round
              ..color = look.brand.withValues(alpha: 0.28)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          )
          ..drawLine(
            beamFrom,
            end,
            Paint()
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round
              ..shader = LinearGradient(
                colors: [
                  look.brand.withValues(alpha: 0.5),
                  look.palette.highlight(look.brand),
                ],
              ).createShader(Rect.fromPoints(beamFrom, end)),
          );
        // Pulses of light run along the beam while the scene drifts.
        final strength = math.sin(math.pi * stageProgress(motion.time, 0.2, 1));
        for (var i = 0; i < 3; i++) {
          final at = (motion.time * 3 + i / 3) % 1;
          if (at > beam || strength == 0) continue;
          final fade = strength * math.sin(math.pi * at);
          final point = Offset.lerp(beamFrom, beamTo, at)!;
          canvas
            ..drawCircle(
              point,
              6,
              Paint()
                ..color = look.brand.withValues(alpha: 0.6 * fade)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
            )
            ..drawCircle(
              point,
              2.2,
              Paint()
                ..color = look.palette
                    .highlight(look.brand)
                    .withValues(alpha: fade),
            );
        }
      }
      if (e >= 0.5) {
        effects
          ..flash(coinAt, stageProgress(e, 0.5, 0.72))
          ..shockwave(coinAt, s * 0.9, stageProgress(e, 0.52, 1), 0.5);
      }
    }),
    StagePlaced(
      at: pixAt,
      size: tokenSize,
      scale: lerpDouble(
        0.7,
        1,
        Curves.easeOutBack.transform(stageProgress(e, 0, 0.4)),
      )!,
      opacity: stageProgress(e, 0, 0.2),
      child: look.token(
        _pixGlyph,
        tokenSize,
        -0.36 + 0.2 * motion.drift + 0.5 * motion.offset,
        shape: _diamond,
        glyphScale: 0.42,
      ),
    ),
    StagePlaced(
      at: coinAt,
      size: tokenSize,
      scale: lerpDouble(
        0.4,
        1,
        Curves.easeOutBack.transform(stageProgress(e, 0.5, 0.8)),
      )!,
      opacity: stageProgress(e, 0.5, 0.6),
      child: look.coin(
        Asset.btc,
        tokenSize,
        lerpDouble(1.3, 0.42, Curves.easeOutCubic.transform(arrive))! -
            0.2 * motion.drift +
            0.5 * motion.offset,
      ),
    ),
  ];
}

// ── 3. Swap: two coins trade places inside two crossing rings ──────────────

List<Widget> _swapScene(_Look look, Size size, SceneMotion motion) {
  final s = size.shortestSide;
  final center = size.center(Offset.zero);
  final e = motion.entrance;
  final coinSize = s * 0.3;
  final radius = coinSize / 2;
  final rx = math.min(size.width * 0.3, s * 0.46);
  final ry = rx * 0.3;
  const tilt = -0.08;
  final grow = Curves.easeOutBack.transform(stageProgress(e, 0, 0.45));
  final swap = Curves.easeInOutCubic.transform(stageProgress(e, 0.25, 1));
  final turn =
      math.pi +
      swap * math.pi +
      0.18 * motion.drift +
      motion.offset * math.pi / 2;
  final rings = [
    StageRing(
      width: rx * 1.15 / radius,
      height: rx * 0.42 / radius,
      tilt: 0.42,
      turns: 0.7,
      phase: 0,
    ),
    StageRing(
      width: rx * 1.15 / radius,
      height: rx * 0.42 / radius,
      tilt: -0.42,
      turns: -0.7,
      phase: math.pi,
    ),
  ];
  final ringAppear = Curves.easeOut.transform(stageProgress(e, 0.05, 0.5));
  final ringOrbit = 0.9 * swap + 0.25 * motion.drift + 0.5 * motion.offset;
  // The light flares as the coins cross.
  final flare = math.sin(math.pi * stageProgress(e, 0.4, 0.8));

  final coins = [
    (asset: Asset.btc, angle: turn),
    (asset: Asset.usdt, angle: turn + math.pi),
  ]..sort((a, b) => math.sin(a.angle).compareTo(math.sin(b.angle)));

  void paintRings(Canvas canvas, StageLayer layer) {
    final effects = look.effects(canvas, radius);
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

  return [
    StagePaintLayer((canvas, size) {
      look.effects(canvas, radius)
        ..glow(center, (0.55 + 0.45 * flare) * ringAppear)
        ..dots(size, 0.6 * stageProgress(e, 0.4, 1));
      paintRings(canvas, StageLayer.back);
    }),
    for (final c in coins)
      StagePlaced(
        at: center + stageOrbitPoint(c.angle, rx, ry, tilt) * grow,
        size: coinSize,
        scale:
            lerpDouble(0.74, 1, stageNearness(c.angle))! *
            lerpDouble(0.6, 1, grow)!,
        opacity: stageProgress(e, 0, 0.2),
        child: look.coin(c.asset, coinSize, -0.3 * math.cos(c.angle)),
      ),
    StagePaintLayer((canvas, size) {
      paintRings(canvas, StageLayer.front);
      look.effects(canvas, radius).sparkles(center, e);
    }),
  ];
}

// ── 4. Security: a vault among the blurred recovery words ─────────────────

List<Widget> _securityScene(_Look look, Size size, SceneMotion motion) {
  final s = size.shortestSide;
  final center = size.center(Offset.zero);
  final e = motion.entrance;
  final vaultSize = s * 0.38;
  final rx = math.min(size.width * 0.38, s * 0.62);
  final ry = math.min(size.height * 0.4, rx * 0.66);
  final chipWidth = (s * 0.2).clamp(56.0, 84.0);
  final turn = 0.12 * motion.drift + motion.offset * math.pi / 4;
  // The words leave the vault one by one; then it seals with a pulse.
  final seal = math.sin(math.pi * stageProgress(e, 0.7, 0.92));
  final ring = const StageRing(
    width: 1.75,
    height: 0.46,
    tilt: -0.22,
    turns: 0.6,
    phase: 0.8,
  );
  final ringAppear = Curves.easeOut.transform(stageProgress(e, 0.3, 0.7));
  final ringOrbit = e + 0.3 * motion.drift;

  return [
    StagePaintLayer((canvas, size) {
      look.effects(canvas, vaultSize / 2)
        ..glow(center, stageProgress(e, 0, 0.4) * (0.8 + 0.2 * seal))
        ..dots(size, 0.6 * stageProgress(e, 0.4, 1))
        ..shockwave(center, s * 0.9, stageProgress(e, 0.72, 1), 0.5)
        ..ring(
          center,
          ring,
          StageLayer.back,
          appear: ringAppear,
          orbit: ringOrbit,
        );
      for (var i = 0; i < 12; i++) {
        final start = 0.2 + i * 0.02;
        final angle = -math.pi / 2 + i * math.pi / 6 + turn;
        final near = stageNearness(angle);
        final out = Curves.easeOutCubic.transform(
          stageProgress(e, start, start + 0.42),
        );
        final bob =
            3 *
            motion.drift *
            math.sin(2 * math.pi * (1.2 * motion.time + i / 12));
        _paintWordChip(
          canvas,
          look,
          center:
              center +
              Offset(rx * math.cos(angle), ry * math.sin(angle)) * out +
              Offset(0, bob),
          width: chipWidth * lerpDouble(0.82, 1, near)!,
          index: i + 1,
          opacity:
              stageProgress(e, start, start + 0.2) * lerpDouble(0.55, 1, near)!,
        );
      }
    }),
    StagePlaced(
      at: center,
      size: vaultSize,
      scale:
          lerpDouble(
            0.7,
            1,
            Curves.easeOutBack.transform(stageProgress(e, 0, 0.45)),
          )! *
          (1 + 0.06 * seal),
      opacity: stageProgress(e, 0, 0.2),
      child: look.token(
        _lockGlyph,
        vaultSize,
        -0.36 + 0.22 * motion.drift + 0.6 * motion.offset,
        shape: _hexagon,
      ),
    ),
    StagePaintLayer((canvas, size) {
      look
          .effects(canvas, vaultSize / 2)
          .ring(
            center,
            ring,
            StageLayer.front,
            appear: ringAppear,
            orbit: ringOrbit,
          );
    }),
  ];
}

/// A recovery word: a small pill with its number and the word, blurred.
/// The scene never shows real words.
void _paintWordChip(
  Canvas canvas,
  _Look look, {
  required Offset center,
  required double width,
  required int index,
  required double opacity,
}) {
  if (opacity <= 0) return;
  final height = width * 0.34;
  final pill = RRect.fromRectAndRadius(
    Rect.fromCenter(center: center, width: width, height: height),
    Radius.circular(height / 2),
  );
  final dark = look.palette.isDark;
  canvas
    ..drawRRect(
      pill,
      Paint()
        ..color = dark
            ? look.ink.withValues(alpha: 0.07 * opacity)
            : look.palette.base.withValues(alpha: opacity),
    )
    ..drawRRect(
      pill,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = look.ink.withValues(alpha: (dark ? 0.14 : 0.1) * opacity),
    );
  final number = TextPainter(
    text: TextSpan(
      text: '$index',
      style: look.label.copyWith(
        fontSize: height * 0.42,
        fontWeight: FontWeight.w600,
        color: look.muted.withValues(alpha: opacity),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final left = pill.left + height * 0.42;
  number.paint(canvas, Offset(left, center.dy - number.height / 2));
  final word = Rect.fromLTRB(
    left + number.width + height * 0.3,
    center.dy - height * 0.12,
    pill.right - height * 0.45,
    center.dy + height * 0.12,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(word, Radius.circular(word.height / 2)),
    Paint()
      ..color = look.muted.withValues(alpha: 0.5 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
  );
}
