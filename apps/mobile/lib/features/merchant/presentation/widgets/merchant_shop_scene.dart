import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_face.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The glyph of the shop: its walls, the frames of its window and of its
/// door, and its awning.
const merchantShopGlyph = 'assets/images/merchant/storefront.svg';

/// The lights of the shop, laid over [merchantShopGlyph]: its window and
/// its door, lit.
const merchantShopLightsGlyph = 'assets/images/merchant/storefront_lights.svg';

/// The art of the screen of Merchant Mode that asks whether the merchant is
/// ready to sell: the shop opens.
///
/// The shop rises and turns toward the viewer. Its lights turn on with a
/// flash and a shockwave, and Pix payments swing in from around the screen
/// into its orbit. The orbit slows down, and the scene rests. A tap turns
/// the shop once: its lights go off as it turns and turn on again.
///
/// [time] runs from 0 to 1 over [duration]: the entrance takes its first
/// [Motion.durationShopOpen], then the orbit slows down to rest at 1.
/// [tap] runs from 0 to 1 over [Motion.durationShopTap] after a tap.
///
/// It is decorative: screen readers skip it.
class MerchantShopScene extends StatelessWidget {
  const MerchantShopScene({super.key, required this.time, this.tap = 0});

  final double time;
  final double tap;

  /// Height of the scene.
  static const double height = 260;

  /// The timeline of [time]: the entrance, then the slow orbit, within
  /// [Motion.durationAmbient] forward and back.
  static final Duration duration = Motion.durationAmbient * 2;

  /// The [time] of the moment [entrance] of the entrance, which runs from
  /// 0 to 1 over [Motion.durationShopOpen].
  static double atEntrance(double entrance) =>
      entrance *
      Motion.durationShopOpen.inMicroseconds /
      duration.inMicroseconds;

  /// When the lights turn on in the entrance: the peak of the scene.
  static const double lightsOn = 0.4;

  /// When the lights turn on again in [tap].
  static const double tapLightsOn = 0.7;

  /// The yaw of the shop at rest: turned a little, so its depth shows.
  static const double restYaw = 0.3;

  /// The Pix payments in the orbit.
  static const int payments = 4;

  @override
  Widget build(BuildContext context) {
    final look = _Look(
      brand: context.colors.primaryColor,
      palette: StagePalette.of(context),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            clipBehavior: Clip.none,
            children: _scene(
              look,
              Size(constraints.maxWidth, height),
              time: time,
              tap: tap,
            ),
          ),
        ),
      ),
    );
  }
}

/// The colors of the scene.
class _Look {
  const _Look({required this.brand, required this.palette});

  final Color brand;
  final StagePalette palette;

  StageEffects effects(Canvas canvas, double radius) => StageEffects(
    canvas,
    tint: brand,
    light: palette.highlight(brand),
    radius: radius,
  );
}

List<Widget> _scene(
  _Look look,
  Size size, {
  required double time,
  required double tap,
}) {
  final s = math.min(size.width, size.height);
  final center = Offset(size.width / 2, size.height * 0.46);
  final shopSize = s * 0.44;
  final radius = shopSize / 2;
  final pixSize = s * 0.2;
  final rx = math.min(size.width * 0.42, s * 0.7);
  final ry = rx * 0.3;
  const tilt = -0.16;
  final ring = StageRing(
    width: rx / radius,
    height: ry / radius,
    tilt: tilt,
    turns: 0.5,
    phase: 1,
  );

  final e = stageProgress(time, 0, MerchantShopScene.atEntrance(1));
  // Slows down to rest at the end of the timeline.
  final settle = Curves.easeOutCubic.transform(time);
  // A sway after the entrance, back to 0 at rest.
  final drift = math.sin(
    math.pi * stageProgress(time, MerchantShopScene.atEntrance(1), 1),
  );

  // The shop rises and turns toward the viewer; a tap turns it once.
  final rise = Curves.easeOutBack.transform(stageProgress(e, 0, 0.4));
  final turnIn = Curves.easeOutCubic.transform(stageProgress(e, 0, 0.45));
  final spin =
      2 *
      math.pi *
      Curves.easeInOutCubic.transform(
        stageProgress(tap, 0, MerchantShopScene.tapLightsOn),
      );
  final yaw = StageToken.faceYaw(
    lerpDouble(-1.25, MerchantShopScene.restYaw, turnIn)! + 0.12 * drift + spin,
  );

  // The lights turn on at the peak, and go off while a tap turns the shop.
  const on = MerchantShopScene.lightsOn;
  final lit = Curves.easeOut.transform(stageProgress(e, on, on + 0.1));
  final dark = stageProgress(tap, 0, MerchantShopScene.tapLightsOn);
  // Exactly on at both ends: a light short of 1 would paint in a layer of
  // its own while the scene rests.
  final lights = dark <= 0 || dark >= 1
      ? lit
      : lit * (1 - math.sin(math.pi * dark));
  final relit = stageProgress(tap, MerchantShopScene.tapLightsOn, 1);

  // The payments swing in from around the screen into the orbit, one after
  // the other, after the lights turn on.
  final ringAppear = Curves.easeOut.transform(stageProgress(e, 0.3, 0.7));
  final ringOrbit = 0.6 * settle;
  // At rest, one payment at each diagonal of the shop, none in front of
  // it. A tap nudges them on and back.
  final orbit =
      math.pi / 4 -
      0.7 * math.pi * (1 - settle) +
      0.35 * math.sin(math.pi * tap);
  final coins = [
    for (var k = 0; k < MerchantShopScene.payments; k++)
      (
        k: k,
        arrive: stageProgress(e, 0.44 + 0.06 * k, 0.78 + 0.06 * k),
        angle: orbit + k * 2 * math.pi / MerchantShopScene.payments,
      ),
  ];
  // Built before they arrive, unseen, so their faces are ready.
  final placed = [
    for (final c in coins)
      (
        angle:
            c.angle -
            0.9 * math.pi * (1 - Curves.easeOutCubic.transform(c.arrive)),
        reach: lerpDouble(2.6, 1, Curves.easeOutCubic.transform(c.arrive))!,
        fade: stageProgress(c.arrive, 0, 0.4),
      ),
  ]..sort((a, b) => math.sin(a.angle).compareTo(math.sin(b.angle)));
  Widget payment(({double angle, double reach, double fade}) c) {
    final near = stageNearness(c.angle);
    return StagePlaced(
      at: center + stageOrbitPoint(c.angle, rx * c.reach, ry * c.reach, tilt),
      size: pixSize,
      scale: lerpDouble(0.7, 1, near)!,
      opacity: c.fade * lerpDouble(0.55, 1, near)!,
      child: GlyphToken(
        glyphPath: stagePixGlyph,
        size: pixSize,
        yaw: -0.55 * math.cos(c.angle),
        tint: look.brand,
        palette: look.palette,
        shape: stagePixShape,
        glyphScale: stagePixGlyphScale,
      ),
    );
  }

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(shopSize * 0.27),
  );

  return [
    StagePaintLayer((canvas, size) {
      final effects = look.effects(canvas, radius)
        ..glow(
          center,
          0.55 * stageProgress(e, 0, 0.4) +
              0.35 * math.sin(math.pi * stageProgress(e, on, 0.8)) +
              0.35 * math.sin(math.pi * relit),
        )
        ..dots(size, 0.5 * stageProgress(e, on, 1))
        ..floor(center, 0.6 * stageProgress(e, 0.1, 0.45));
      // The flash at the peak, and again when a tap turns the lights on.
      if (e >= on) {
        effects
          ..flash(center, stageProgress(e, on, on + 0.25))
          ..shockwave(center, s * 1.1, stageProgress(e, on + 0.02, 0.95), 0.6);
      }
      if (relit > 0) {
        effects
          ..flash(center, stageProgress(relit, 0, 0.7))
          ..shockwave(center, s * 0.9, relit, 0.45);
      }
      effects
        ..sparkles(center, e)
        ..ring(
          center,
          ring,
          StageLayer.back,
          appear: ringAppear,
          orbit: ringOrbit,
        );
    }),
    for (final c in placed)
      if (math.sin(c.angle) < 0) payment(c),
    StagePlaced(
      at: center,
      size: shopSize,
      scale: lerpDouble(0.6, 1, rise)!,
      opacity: stageProgress(e, 0, 0.2),
      child: StageToken(
        shape: shape,
        size: shopSize,
        yaw: yaw,
        tint: look.brand,
        base: look.palette.base,
        centered: true,
        face: RepaintBoundary(
          child: StageFace(
            shape: shape,
            size: shopSize,
            tint: look.brand,
            palette: look.palette,
            glyph: (color) =>
                _ShopGlyph(size: shopSize * 0.74, color: color, lights: lights),
          ),
        ),
      ),
    ),
    StagePaintLayer((canvas, size) {
      look
          .effects(canvas, radius)
          .ring(
            center,
            ring,
            StageLayer.front,
            appear: ringAppear,
            orbit: ringOrbit,
          );
    }),
    for (final c in placed)
      if (math.sin(c.angle) >= 0) payment(c),
  ];
}

/// The shop on its face, in [color], with its lights on by [lights]. Both
/// pictures always build, so the lights show at once when they turn on.
class _ShopGlyph extends StatelessWidget {
  const _ShopGlyph({
    required this.size,
    required this.color,
    required this.lights,
  });

  final double size;
  final Color color;
  final double lights;

  @override
  Widget build(BuildContext context) {
    final colors = TwoToneGlyphColors(color);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          SvgPicture.asset(
            merchantShopGlyph,
            width: size,
            height: size,
            colorMapper: colors,
          ),
          Opacity(
            opacity: lights.clamp(0.0, 1.0),
            child: SvgPicture.asset(
              merchantShopLightsGlyph,
              width: size,
              height: size,
              colorMapper: colors,
            ),
          ),
        ],
      ),
    );
  }
}
