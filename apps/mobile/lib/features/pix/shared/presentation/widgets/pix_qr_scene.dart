import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Where the scene of a Pix QR code being created is in its motion.
@immutable
class PixQrMotion {
  const PixQrMotion({
    this.assemble = 0,
    this.cycle = 0,
    this.waiting = 0,
    this.finale = 0,
  });

  /// The code assembling, from 0 to 1: its three finder patterns, then its
  /// modules in a wave from the top left, and the Pix mark at its center.
  final double assemble;

  /// A slow cycle, from 0 to 1, that repeats while the code is created: a
  /// beam scans the code from top to bottom, the modules it passes light
  /// up, and the mark sways.
  final double cycle;

  /// How much of that waiting motion shows, from 0 to 1. It fades in once
  /// the code has assembled, and out as the code locks in.
  final double waiting;

  /// The code locking in once it is ready, from 0 to 1: its modules pop
  /// from the center out, and a flash, a shockwave, and a burst leave the
  /// mark, which spins once.
  final double finale;
}

/// The art of a Pix QR code being created: a code that assembles, then is
/// scanned while the request runs, with the Pix mark on a diamond token at
/// its center, in the brand pink and the colors of the [StagePalette].
///
/// The code is drawn, not encoded: no reader finds data in it. The scene
/// is decorative; the caption of the overlay tells the step.
class PixQrScene extends StatelessWidget {
  const PixQrScene({super.key, required this.motion});

  final PixQrMotion motion;

  /// Side of the code, as the QR code of the charge screens.
  static const double codeSize = 220;

  /// Width of the Pix mark at the center of the code.
  static const double markSize = 74;

  /// Margin of the tile around the code.
  static const double _tilePadding = 16;

  static const _pixGlyph = 'assets/icons/menu/navigation/pix.svg';

  /// The Pix token: a diamond, like the Pix symbol on its face.
  static const _diamond = StarBorder.polygon(sides: 4, pointRounding: 0.32);

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final palette = StagePalette.of(context);
    final light = palette.highlight(brand);
    // The shockwave crosses the whole screen.
    final reach = MediaQuery.sizeOf(context).longestSide;
    final m = motion;
    final cycle = 2 * math.pi * m.cycle;
    final f = m.finale;
    const side = codeSize + 2 * _tilePadding;

    final mark = stageProgress(m.assemble, 0.35, 0.8);
    // The mark sways while it waits, then spins once as the code locks in.
    final turn =
        0.28 +
        0.32 * math.sin(cycle) * m.waiting +
        2 * math.pi * Curves.easeInOutCubic.transform(stageProgress(f, 0, 0.6));

    const center = Offset(side / 2, side / 2);
    StageEffects effects(Canvas canvas, double radius) =>
        StageEffects(canvas, tint: brand, light: light, radius: radius);
    final painter = _CodePainter(
      motion: m,
      brand: brand,
      light: light,
      origin: center - const Offset(codeSize / 2, codeSize / 2),
    );

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: side,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            StagePaintLayer((canvas, size) {
              final code = effects(canvas, codeSize / 2);
              final appear = Curves.easeOut.transform(
                stageProgress(m.assemble, 0, 0.35),
              );
              code.glow(
                center,
                0.32 * appear * (1 + 0.15 * math.sin(2 * cycle) * m.waiting),
              );
              painter.tile(canvas, appear);
              painter.incoming(canvas, effects(canvas, markSize / 2));
              code
                ..shockwave(center, reach, stageProgress(f, 0, 0.7), 1)
                ..shockwave(center, reach, stageProgress(f, 0.1, 0.85), 0.45);
              if (f > 0 && f < 1) {
                code.flash(center, stageProgress(f, 0, 0.32));
              }
              effects(canvas, markSize / 2).glow(
                center,
                mark * (0.75 + 0.2 * math.sin(2 * cycle) * m.waiting),
              );
            }),
            StagePaintLayer((canvas, size) => painter.paint(canvas)),
            StagePlaced(
              at: center + Offset(0, -3 * math.sin(cycle) * m.waiting),
              size: markSize,
              scale:
                  lerpDouble(0.4, 1, Curves.easeOutBack.transform(mark))! *
                  (1 + 0.1 * math.sin(math.pi * stageProgress(f, 0, 0.32))),
              opacity: stageProgress(m.assemble, 0.35, 0.5),
              child: GlyphToken(
                glyphPath: _pixGlyph,
                shape: _diamond,
                size: markSize,
                yaw: StageToken.faceYaw(turn),
                tint: brand,
                palette: palette,
                glyphScale: 0.42,
              ),
            ),
            StagePaintLayer((canvas, size) {
              effects(
                canvas,
                markSize / 2,
              ).burst(center, f, start: 0, end: 0.9);
              effects(
                canvas,
                codeSize / 2,
              ).sparkles(center, f, delay: -0.16, span: 0.2);
            }),
          ],
        ),
      ),
    );
  }
}

/// Cells on each side of the code, as in a QR code of version 2.
const _grid = 25;

/// A dark module of the code.
class _Module {
  const _Module(this.col, this.row, this.wave, this.twinkle);

  final int col;
  final int row;

  /// When it pops in as the code assembles, from 0 to 1: along a wave from
  /// the top left.
  final double wave;

  /// Phase of its twinkle while the code waits.
  final double twinkle;
}

/// Whether a cell belongs to a finder pattern or to its clear margin.
bool _inFinder(int col, int row) =>
    (col < 8 && row < 8) ||
    (col >= _grid - 8 && row < 8) ||
    (col < 8 && row >= _grid - 8);

/// Whether a cell is in the clear center, under the Pix mark.
bool _inCenter(int col, int row) =>
    (col - _grid ~/ 2).abs() <= 4 && (row - _grid ~/ 2).abs() <= 4;

/// The modules of the code: a fixed pattern, the same on every frame, with
/// the timing lines of a real code between the finder patterns.
final _modules = () {
  final random = math.Random(5);
  return [
    for (var row = 0; row < _grid; row++)
      for (var col = 0; col < _grid; col++)
        if (!_inFinder(col, row) &&
            !_inCenter(col, row) &&
            (row == 6 || col == 6
                ? (row + col).isEven
                : random.nextDouble() < 0.5))
          _Module(
            col,
            row,
            (col + row) / (2 * (_grid - 1)),
            random.nextDouble(),
          ),
  ];
}();

/// Top-left cells of the three finder patterns, in the order they draw in.
const _finders = [(0, 0), (_grid - 7, 0), (0, _grid - 7)];

/// Paints the code: its tile, its finder patterns and modules, the scan
/// beam, and the particles that flow into it while it waits.
class _CodePainter {
  _CodePainter({
    required this.motion,
    required this.brand,
    required this.light,
    required this.origin,
  });

  final PixQrMotion motion;
  final Color brand;
  final Color light;

  /// Top left corner of the code.
  final Offset origin;

  static const double _size = PixQrScene.codeSize;
  static const double _cell = _size / _grid;

  Offset get _center => origin + const Offset(_size / 2, _size / 2);

  /// The rounded tile around the code: a faint plate and its outline,
  /// brighter once the code locks in.
  void tile(Canvas canvas, double appear) {
    if (appear == 0) return;
    final lock = stageProgress(motion.finale, 0, 0.3);
    final rect = RRect.fromRectAndRadius(
      (origin & const Size.square(_size)).inflate(PixQrScene._tilePadding),
      const Radius.circular(24),
    );
    canvas
      ..drawRRect(rect, Paint()..color = brand.withValues(alpha: 0.05 * appear))
      ..drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = brand.withValues(alpha: (0.25 + 0.35 * lock) * appear),
      );
  }

  /// Particles drawn into the code from all around while it waits, as the
  /// data of the charge.
  void incoming(Canvas canvas, StageEffects effects) {
    final waiting = motion.waiting;
    if (waiting == 0) return;
    const half = _size / 2;
    final particles = stageParticles.take(18).toList();
    for (final (i, particle) in particles.indexed) {
      final p = (motion.cycle + i / particles.length) % 1;
      final distance = lerpDouble(
        half * (1.55 + 0.9 * particle.speed),
        half * 0.92,
        Curves.easeInCubic.transform(p),
      )!;
      effects.drawParticle(
        _center + Offset.fromDirection(particle.angle, distance),
        particle,
        scale: lerpDouble(0.7, 1.1, p)!,
        strength: 0.9 * waiting * math.sin(math.pi * p),
      );
    }
  }

  void paint(Canvas canvas) {
    final m = motion;
    final cycle = 2 * math.pi * m.cycle;
    // The beam sweeps the code from top to bottom once per cycle, and is
    // dark at both ends, so the cycle loops without a jump.
    final beamY = origin.dy + _size * Curves.easeInOutSine.transform(m.cycle);
    final beam = m.waiting * math.sin(math.pi * m.cycle);
    final dot = Paint();

    for (final (k, (col, row)) in _finders.indexed) {
      final p = stageProgress(m.assemble, 0.05 + 0.08 * k, 0.4 + 0.08 * k);
      if (p == 0) continue;
      final scale =
          lerpDouble(0.5, 1, Curves.easeOutBack.transform(p))! *
          (1 + 0.08 * math.sin(math.pi * stageProgress(m.finale, 0.04, 0.34)));
      final box = Rect.fromLTWH(
        origin.dx + col * _cell,
        origin.dy + row * _cell,
        7 * _cell,
        7 * _cell,
      );
      final finder = Rect.fromCenter(
        center: box.center,
        width: box.width * scale,
        height: box.height * scale,
      );
      final unit = finder.width / 7;
      dot.color = brand.withValues(alpha: p * lerpDouble(1, 0.8, m.waiting)!);
      final ring = Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(RRect.fromRectAndRadius(finder, Radius.circular(unit * 2)))
        ..addRRect(
          RRect.fromRectAndRadius(
            finder.deflate(unit),
            Radius.circular(unit * 1.4),
          ),
        );
      canvas
        ..drawPath(ring, dot)
        ..drawRRect(
          RRect.fromRectAndRadius(
            finder.deflate(unit * 2),
            Radius.circular(unit * 0.9),
          ),
          dot,
        );
    }

    // The modules dim while the code waits; the beam lights those it
    // passes. Once the code is ready, they lock in from the center out.
    final dim = lerpDouble(1, 0.5, m.waiting)!;
    const reach = _size / 2 * math.sqrt2;
    for (final module in _modules) {
      final start = 0.2 + 0.55 * module.wave;
      final appear = stageProgress(m.assemble, start, start + 0.2);
      if (appear == 0) continue;
      final at =
          origin +
          Offset((module.col + 0.5) * _cell, (module.row + 0.5) * _cell);
      final scan =
          beam * math.exp(-math.pow((at.dy - beamY) / (2.5 * _cell), 2));
      final twinkle =
          1 -
          0.18 *
              m.waiting *
              (0.5 + 0.5 * math.sin(2 * cycle + 2 * math.pi * module.twinkle));
      final near = (at - _center).distance / reach;
      final lock = stageProgress(
        m.finale,
        0.02 + 0.14 * near,
        0.16 + 0.14 * near,
      );
      final alpha = math.max(
        appear * math.min(1, dim * twinkle + 0.5 * scan),
        lock,
      );
      final size =
          _cell *
          0.82 *
          Curves.easeOutBack.transform(appear) *
          (1 + 0.18 * scan + 0.3 * math.sin(math.pi * lock));
      dot.color = brand.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: at, width: size, height: size),
          Radius.circular(size * 0.32),
        ),
        dot,
      );
    }

    if (beam > 0) _beam(canvas, beamY, beam);
  }

  /// The scan beam at [y], with a trail of light above it.
  void _beam(Canvas canvas, double y, double strength) {
    final left = origin.dx + 6;
    final right = origin.dx + _size - 6;
    final trail = Rect.fromLTRB(left, y - 28, right, y);
    canvas.drawRect(
      trail,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            brand.withValues(alpha: 0),
            brand.withValues(alpha: 0.22 * strength),
          ],
        ).createShader(trail),
    );
    canvas.drawLine(
      Offset(left, y),
      Offset(right, y),
      Paint()
        ..strokeWidth = 6
        ..color = brand.withValues(alpha: 0.5 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    final core = Rect.fromLTRB(left, y - 1, right, y + 1);
    canvas.drawRect(
      core,
      Paint()
        ..shader = LinearGradient(
          colors: [
            light.withValues(alpha: 0),
            light.withValues(alpha: 0.95 * strength),
            light.withValues(alpha: 0),
          ],
        ).createShader(core),
    );
  }
}
