import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_face.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';

/// The coin of [asset] on a stage, [size] wide, turned by [yaw]: its icon
/// in [tint] on the metal of the [palette].
class AssetCoin extends StatelessWidget {
  const AssetCoin({
    super.key,
    required this.asset,
    required this.size,
    required this.yaw,
    required this.tint,
    required this.palette,
  });

  final Asset asset;
  final double size;
  final double yaw;
  final Color tint;
  final StagePalette palette;

  @override
  Widget build(BuildContext context) {
    return StageToken(
      size: size,
      yaw: yaw,
      tint: tint,
      base: palette.base,
      face: RepaintBoundary(
        child: StageFace.asset(asset, size: size, tint: tint, palette: palette),
      ),
    );
  }
}

/// A token on a stage with the two-tone glyph of [glyphPath] on its face,
/// such as the Mooze coin: [glyphScale] of its width, in [tint].
///
/// A token in another shape than a circle turns around the middle of its
/// thickness, see [StageToken.centered].
class GlyphToken extends StatelessWidget {
  const GlyphToken({
    super.key,
    required this.glyphPath,
    required this.size,
    required this.yaw,
    required this.tint,
    required this.palette,
    this.shape = const CircleBorder(),
    this.glyphScale = 0.48,
  });

  final String glyphPath;
  final double size;
  final double yaw;
  final Color tint;
  final StagePalette palette;
  final OutlinedBorder shape;
  final double glyphScale;

  @override
  Widget build(BuildContext context) {
    final glyph = size * glyphScale;
    return StageToken(
      shape: shape,
      size: size,
      yaw: yaw,
      tint: tint,
      base: palette.base,
      centered: shape is! CircleBorder,
      face: RepaintBoundary(
        child: StageFace(
          shape: shape,
          size: size,
          tint: tint,
          palette: palette,
          glyph: (color) => SvgPicture.asset(
            glyphPath,
            width: glyph,
            height: glyph,
            colorMapper: TwoToneGlyphColors(color),
          ),
        ),
      ),
    );
  }
}

/// A point on an orbit, an ellipse of radii [rx] and [ry] tilted by
/// [tilt], at [angle] from its center. It matches the rings that
/// [StageRing] draws: positive sines are its lower, nearer half.
Offset stageOrbitPoint(double angle, double rx, double ry, double tilt) {
  final x = rx * math.cos(angle);
  final y = ry * math.sin(angle);
  return Offset(
    x * math.cos(tilt) - y * math.sin(tilt),
    x * math.sin(tilt) + y * math.cos(tilt),
  );
}

/// How near a point at [angle] on an orbit is, from 0 at the back to 1 at
/// the front.
double stageNearness(double angle) => (math.sin(angle) + 1) / 2;

/// [child], [size] wide, centered on [at] in a [Stack], at [scale] and
/// [opacity].
class StagePlaced extends StatelessWidget {
  const StagePlaced({
    super.key,
    required this.at,
    required this.size,
    this.scale = 1,
    this.opacity = 1,
    required this.child,
  });

  final Offset at;
  final double size;
  final double scale;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}

/// A layer of a scene in a [Stack], painted by [paint]. A scene rebuilds
/// only while it moves, so the layer repaints on every build.
class StagePaintLayer extends StatelessWidget {
  const StagePaintLayer(this.paint, {super.key});

  final void Function(Canvas canvas, Size size) paint;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: _LayerPainter(paint))),
    );
  }
}

class _LayerPainter extends CustomPainter {
  const _LayerPainter(this.draw);

  final void Function(Canvas canvas, Size size) draw;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size);

  @override
  bool shouldRepaint(_LayerPainter oldDelegate) => true;
}
