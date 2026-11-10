import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The token at the center of a celebration stage, a coin or a medal, seen
/// in perspective: turned by [yaw] around its vertical axis and tipped
/// slightly forward. Thin layers of its [shape] stacked behind the [face]
/// form its edge, alternating in shade like the ridges of a coin.
///
/// The face always looks toward the viewer, so [yaw] stays within a
/// quarter turn on each side. A token that spins further shows a face on
/// each half turn: see [StageToken.faceYaw].
class StageToken extends StatelessWidget {
  const StageToken({
    super.key,
    this.shape = const CircleBorder(),
    required this.size,
    required this.yaw,
    required this.tint,
    required this.base,
    this.centered = false,
    required this.face,
  });

  final OutlinedBorder shape;

  /// Diameter of the face.
  final double size;
  final double yaw;
  final Color tint;

  /// The metal of the token, under the [tint] of its edge.
  final Color base;

  /// Whether the token turns around the middle of its thickness, not
  /// around its face. A token that spins turns around its middle, so its
  /// edge stays in place as it passes edge-on.
  final bool centered;

  final Widget face;

  static const int _edgeLayers = 12;

  /// The yaw at which a token that has turned by [turn] shows its face:
  /// [turn] brought within a quarter turn on each side. Each half turn
  /// shows the face again, as if the token had a face on each side.
  static double faceYaw(double turn) =>
      turn - (turn / math.pi).roundToDouble() * math.pi;

  @override
  Widget build(BuildContext context) {
    final depth = size * 0.11;
    final ridge = Color.alphaBlend(tint.withValues(alpha: 0.22), base);
    final groove = Color.alphaBlend(tint.withValues(alpha: 0.08), base);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateX(-0.12)
        ..rotateY(yaw)
        ..multiply(Matrix4.translationValues(0, 0, centered ? -depth / 2 : 0)),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            // From the back to the face: no depth test, so the farthest
            // layer paints first.
            for (var i = _edgeLayers; i >= 1; i--)
              Transform(
                transform: Matrix4.translationValues(
                  0,
                  0,
                  depth * i / _edgeLayers,
                ),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: i.isEven ? ridge : groove,
                    shape: shape.copyWith(
                      side: BorderSide(
                        color: tint.withValues(
                          alpha: i == _edgeLayers ? 0.55 : 0.2,
                        ),
                      ),
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            face,
          ],
        ),
      ),
    );
  }
}
