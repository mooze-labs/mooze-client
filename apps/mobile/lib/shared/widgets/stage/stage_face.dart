import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';

/// The face of a stage token in its [shape]: a plate of the metal of the
/// [palette] with a rim in [tint], a fine inner line, a soft glow, and a
/// glyph in [tint], embossed with a shadow.
///
/// [glyph] builds the symbol in a color: once in the shadow color of the
/// [palette], offset, then in [tint] on top.
class StageFace extends StatelessWidget {
  const StageFace({
    super.key,
    this.shape = const CircleBorder(),
    required this.size,
    required this.tint,
    required this.palette,
    required this.glyph,
  });

  /// The face of the coin of [asset], with the icon of the asset as its
  /// glyph.
  factory StageFace.asset(
    Asset asset, {
    Key? key,
    required double size,
    required Color tint,
    required StagePalette palette,
  }) {
    final glyph = size * CoinGlyphColors.scaleOf(asset);
    return StageFace(
      key: key,
      size: size,
      tint: tint,
      palette: palette,
      glyph: (color) => SvgPicture.asset(
        asset.iconPath,
        width: glyph,
        height: glyph,
        colorMapper: CoinGlyphColors.of(asset, color),
      ),
    );
  }

  final OutlinedBorder shape;

  /// Width of the face.
  final double size;
  final Color tint;
  final StagePalette palette;
  final Widget Function(Color color) glyph;

  @override
  Widget build(BuildContext context) {
    final shape = this.shape;
    return CustomPaint(
      painter: shape is CircleBorder
          ? _CoinFacePainter(tint: tint, palette: palette)
          : _PlateFacePainter(shape: shape, tint: tint, palette: palette),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(1.2, 1.8),
                child: glyph(palette.shade),
              ),
              glyph(tint),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round face: a disc with its rim and a glint on the rim.
class _CoinFacePainter extends CustomPainter {
  const _CoinFacePainter({required this.tint, required this.palette});

  final Color tint;
  final StagePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final base = palette.base;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final rim = radius * 0.09;

    // The body: lit from the top left.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: [
            Color.alphaBlend(tint.withValues(alpha: 0.24), base),
            Color.alphaBlend(tint.withValues(alpha: 0.08), base),
            base,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    // The rim: bright where the light hits it.
    canvas.drawCircle(
      center,
      radius - rim / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim
        ..shader = SweepGradient(
          colors: [
            tint,
            tint.withValues(alpha: 0.35),
            tint.withValues(alpha: 0.75),
            tint.withValues(alpha: 0.3),
            tint,
          ],
          stops: const [0, 0.3, 0.55, 0.8, 1],
          transform: const GradientRotation(-2.2),
        ).createShader(rect),
    );
    // The bevel inside the rim.
    canvas.drawCircle(
      center,
      radius - rim - 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = palette.shade,
    );
    canvas.drawCircle(
      center,
      radius * 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = tint.withValues(alpha: 0.22),
    );
    // A soft light under the symbol.
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()
        ..shader = RadialGradient(
          colors: [tint.withValues(alpha: 0.28), tint.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.62)),
    );
    // A glint on the upper left of the rim.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - rim * 0.5),
      -2.75,
      0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = rim * 0.45
        ..color = palette.glint.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_CoinFacePainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.palette != palette;
}

/// A face in any other shape, drawn along the outline of the shape.
class _PlateFacePainter extends CustomPainter {
  const _PlateFacePainter({
    required this.shape,
    required this.tint,
    required this.palette,
  });

  final OutlinedBorder shape;

  final Color tint;
  final StagePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final base = palette.base;
    final glint = palette.glint;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;
    final rim = radius * 0.09;
    Path outline(double inset) => shape.getOuterPath(rect.deflate(inset));
    Paint stroke(double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round;

    // The body: lit from the top left.
    canvas.drawPath(
      outline(0),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: [
            Color.alphaBlend(tint.withValues(alpha: 0.24), base),
            Color.alphaBlend(tint.withValues(alpha: 0.08), base),
            base,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    // The rim: bright where the light hits it.
    canvas.drawPath(
      outline(rim / 2),
      stroke(rim)
        ..shader = SweepGradient(
          colors: [
            tint,
            tint.withValues(alpha: 0.35),
            tint.withValues(alpha: 0.75),
            tint.withValues(alpha: 0.3),
            tint,
          ],
          stops: const [0, 0.3, 0.55, 0.8, 1],
          transform: const GradientRotation(-2.2),
        ).createShader(rect),
    );
    // The bevel inside the rim, and a fine line further in.
    canvas.drawPath(outline(rim + 0.8), stroke(1.4)..color = palette.shade);
    canvas.drawPath(
      outline(radius * 0.2),
      stroke(1)..color = tint.withValues(alpha: 0.22),
    );
    // A soft light under the emblem.
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()
        ..shader = RadialGradient(
          colors: [tint.withValues(alpha: 0.28), tint.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.62)),
    );
    // A glint on the upper left side of the rim.
    canvas.drawPath(
      outline(rim / 2),
      stroke(rim * 0.45)
        ..shader = SweepGradient(
          colors: [
            glint.withValues(alpha: 0),
            glint.withValues(alpha: 0.55),
            glint.withValues(alpha: 0),
          ],
          stops: const [0.56, 0.634, 0.71],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_PlateFacePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.tint != tint ||
      oldDelegate.palette != palette;
}
