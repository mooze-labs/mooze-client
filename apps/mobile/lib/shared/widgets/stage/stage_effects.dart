import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Progress of [t] through the window from [begin] to [end], from 0 to 1.
double stageProgress(double t, double begin, double end) =>
    ((t - begin) / (end - begin)).clamp(0.0, 1.0);

/// Which part of a stage a painter draws: what is behind the token at the
/// center, or what passes in front of it.
enum StageLayer { back, front }

/// One ring around the token: an ellipse, tilted, whose bright head orbits
/// [turns] times and slows down to rest.
class StageRing {
  const StageRing({
    required this.width,
    required this.height,
    required this.tilt,
    required this.turns,
    required this.phase,
  });

  /// Radii as multiples of the token radius.
  final double width;
  final double height;
  final double tilt;

  /// Turns of the head, negative for the other direction.
  final double turns;
  final double phase;
}

/// The two rings of the stages, wide first.
const stageRings = [
  StageRing(width: 1.8, height: 0.5, tilt: -0.3, turns: 1.4, phase: 0.6),
  StageRing(width: 1.6, height: 0.42, tilt: 0.24, turns: -0.9, phase: 2.6),
];

/// A particle of a stage: thrown out from the token, drawn into it, or
/// falling from it.
class StageParticle {
  const StageParticle(
    this.angle,
    this.speed,
    this.size,
    this.delay,
    this.bright,
  );

  final double angle;
  final double speed;
  final double size;
  final double delay;

  /// Whether it shines in the light color, not in the tint.
  final bool bright;
}

/// The particles of the stages.
final stageParticles = () {
  final random = math.Random(11);
  return [
    for (var i = 0; i < 28; i++)
      StageParticle(
        random.nextDouble() * math.pi * 2,
        0.35 + random.nextDouble() * 0.65,
        1 + random.nextDouble() * 1.6,
        random.nextDouble() * 0.12,
        random.nextDouble() < 0.3,
      ),
  ];
}();

/// A faint dot that stays on the stage once the scene rests.
class _Dot {
  const _Dot(this.x, this.y, this.size);

  /// Position as a share of the stage size.
  final double x;
  final double y;
  final double size;
}

final _dots = () {
  final random = math.Random(3);
  return [
    for (var i = 0; i < 14; i++)
      _Dot(
        0.04 + random.nextDouble() * 0.92,
        0.04 + random.nextDouble() * 0.92,
        0.8 + random.nextDouble(),
      ),
  ];
}();

/// Angles and distances, in token radii, of the sparkles around the token,
/// and when each one twinkles.
const _sparkles = [
  (angle: -2.4, distance: 1.45, start: 0.46),
  (angle: -0.5, distance: 1.7, start: 0.55),
  (angle: 0.9, distance: 1.35, start: 0.62),
  (angle: 2.5, distance: 1.6, start: 0.7),
  (angle: -1.4, distance: 2.0, start: 0.76),
];

/// The effects of the celebration stages, around a token at the center,
/// painted on [canvas] in [tint] with highlights in [light]. Sizes are
/// multiples of [radius], the radius of the token.
///
/// Each stage sets its own timeline: it computes the progress or the
/// strength of every effect and paints them in order, from the back.
class StageEffects {
  const StageEffects(
    this.canvas, {
    required this.tint,
    required this.light,
    required this.radius,
  });

  final Canvas canvas;
  final Color tint;
  final Color light;
  final double radius;

  /// Height of the floor under the token at [center].
  Offset floorOf(Offset center) => Offset(center.dx, center.dy + radius * 1.45);

  /// The light behind the token.
  void glow(Offset center, double strength) {
    if (strength == 0) return;
    final size = radius * 2.3;
    canvas.drawCircle(
      center,
      size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            tint.withValues(alpha: 0.4 * strength),
            tint.withValues(alpha: 0.12 * strength),
            tint.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: center, radius: size)),
    );
  }

  /// A thin column of light from the floor up through the token, to [top].
  /// A [top] past the top of the screen, for example minus the height of
  /// the screen, makes it reach the top edge with no visible end.
  void beam(Offset center, double top, double strength) {
    if (strength == 0) return;
    final floor = floorOf(center).dy;
    final soft = Rect.fromLTRB(center.dx - 36, top, center.dx + 36, floor);
    canvas.drawRect(
      soft,
      Paint()
        ..shader = LinearGradient(
          colors: [
            tint.withValues(alpha: 0),
            tint.withValues(alpha: 0.1 * strength),
            tint.withValues(alpha: 0),
          ],
        ).createShader(soft),
    );
    final core = Rect.fromLTRB(center.dx - 1, top, center.dx + 1, floor);
    canvas.drawRect(
      core,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tint.withValues(alpha: 0),
            tint.withValues(alpha: 0.5 * strength),
          ],
        ).createShader(core),
    );
  }

  /// Ripples on the floor under the token, with a point of light at their
  /// center.
  void floor(Offset center, double strength) {
    if (strength == 0) return;
    final floor = floorOf(center);
    const sizes = [0.55, 1.0, 1.55, 2.2];
    const alphas = [0.55, 0.38, 0.22, 0.12];
    for (var i = 0; i < sizes.length; i++) {
      final width = radius * sizes[i] * 2;
      canvas.drawOval(
        Rect.fromCenter(center: floor, width: width, height: width * 0.24),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = tint.withValues(alpha: alphas[i] * strength),
      );
    }
    final spot = radius * 0.5;
    canvas.drawOval(
      Rect.fromCenter(center: floor, width: spot * 2, height: spot * 0.6),
      Paint()
        ..shader = RadialGradient(
          colors: [
            light.withValues(alpha: 0.7 * strength),
            tint.withValues(alpha: 0.4 * strength),
            tint.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(Rect.fromCircle(center: floor, radius: spot)),
    );
  }

  /// Faint dots that settle on a stage of [size].
  void dots(Size size, double strength) {
    if (strength == 0) return;
    final paint = Paint()..color = tint.withValues(alpha: 0.4 * strength);
    for (final dot in _dots) {
      canvas.drawCircle(
        Offset(dot.x * size.width, dot.y * size.height),
        dot.size,
        paint,
      );
    }
  }

  /// A ring of light that leaves the center and fades as it grows to
  /// [reach]. [p] is its progress; [strength] scales its light.
  void shockwave(Offset center, double reach, double p, double strength) {
    if (p <= 0 || p >= 1) return;
    final grow = Curves.easeOutCubic.transform(p);
    final size = reach * grow;
    final fade = math.pow(1 - p, 1.4).toDouble() * strength;
    final width = lerpDouble(16, 1.5, grow)!;
    canvas.drawCircle(
      center,
      size,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.4
        ..color = tint.withValues(alpha: 0.35 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      center,
      size,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = tint.withValues(alpha: 0.9 * fade),
    );
  }

  /// A flash at the center that grows and fades as [p] runs from 0 to 1.
  void flash(Offset center, double p) {
    if (p >= 1) return;
    final fade = 1 - p;
    final size = lerpDouble(
      radius * 0.3,
      radius * 2.4,
      Curves.easeOutCubic.transform(p),
    )!;
    canvas.drawCircle(
      center,
      size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            light.withValues(alpha: 0.9 * fade),
            tint.withValues(alpha: 0.6 * fade),
            tint.withValues(alpha: 0),
          ],
          stops: const [0, 0.25, 1],
        ).createShader(Rect.fromCircle(center: center, radius: size)),
    );
  }

  /// Particles thrown out from the center. Each one leaves at [start] plus
  /// its delay, slows down, and fades out by [end].
  void burst(
    Offset center,
    double t, {
    required double start,
    required double end,
  }) {
    final distance = radius * 3.4;
    for (final particle in stageParticles) {
      final p = stageProgress(t, start + particle.delay, end);
      if (p <= 0 || p >= 1) continue;
      final travel =
          distance * particle.speed * Curves.easeOutCubic.transform(p);
      final position =
          center +
          Offset(math.cos(particle.angle), math.sin(particle.angle)) * travel;
      final fade = math.pow(1 - p, 1.2).toDouble();
      drawParticle(position, particle, scale: 1 - 0.4 * p, strength: fade);
    }
  }

  /// One [particle] at [position], at [scale] of its size and [strength]
  /// of its light.
  void drawParticle(
    Offset position,
    StageParticle particle, {
    required double scale,
    required double strength,
  }) {
    canvas.drawCircle(
      position,
      particle.size * scale,
      Paint()
        ..color = (particle.bright ? light : tint).withValues(
          alpha: (particle.bright ? 0.95 : 0.7) * strength,
        ),
    );
  }

  /// One ring: the half behind the token on the [StageLayer.back] layer,
  /// the half in front on the [StageLayer.front] layer. The ring is faint
  /// all around and bright near its head, which leaves a tail as it
  /// orbits.
  ///
  /// [appear] fades the ring in; [orbit] runs its head from its phase
  /// through its turns. [scale] sizes it, by default growing from 0.7 to 1
  /// as it appears.
  void ring(
    Offset center,
    StageRing ring,
    StageLayer layer, {
    required double appear,
    required double orbit,
    double? scale,
  }) {
    if (appear == 0) return;
    final head = ring.phase + ring.turns * 2 * math.pi * orbit;
    final size = scale ?? lerpDouble(0.7, 1, appear)!;
    final rx = radius * ring.width * size;
    final ry = radius * ring.height * size;
    final cos = math.cos(ring.tilt);
    final sin = math.sin(ring.tilt);
    Offset at(double angle) {
      final x = rx * math.cos(angle);
      final y = ry * math.sin(angle);
      return center + Offset(x * cos - y * sin, x * sin + y * cos);
    }

    // The far half of the ellipse is its upper half, behind the token.
    bool behind(double angle) => math.sin(angle) < 0;
    final mine = layer == StageLayer.back;

    // A soft glow along the half.
    final glow = Path();
    const steps = 96;
    var started = false;
    for (var i = 0; i <= steps; i++) {
      final angle = 2 * math.pi * i / steps;
      if (behind(angle) != mine) {
        started = false;
        continue;
      }
      final point = at(angle);
      if (started) {
        glow.lineTo(point.dx, point.dy);
      } else {
        glow.moveTo(point.dx, point.dy);
        started = true;
      }
    }
    canvas.drawPath(
      glow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = tint.withValues(alpha: 0.28 * appear)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // The line, brighter toward the head.
    final direction = ring.turns.sign;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < steps; i++) {
      final from = 2 * math.pi * i / steps;
      final to = 2 * math.pi * (i + 1) / steps;
      if (behind((from + to) / 2) != mine) continue;
      final gap = ((head - from) * direction) % (2 * math.pi);
      final tail = math.pow(1 - gap / (2 * math.pi), 3).toDouble();
      line
        ..strokeWidth = 1.2 + 1.2 * tail
        ..color = tint.withValues(alpha: (0.2 + 0.8 * tail) * appear);
      canvas.drawLine(at(from), at(to), line);
    }

    // The head, on the layer of its half.
    final headAngle = head % (2 * math.pi);
    if (behind(headAngle) == mine) {
      final point = at(headAngle);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = tint.withValues(alpha: 0.6 * appear)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        point,
        2.2,
        Paint()..color = light.withValues(alpha: appear),
      );
    }
  }

  /// Four-point stars around the token that twinkle once each, over
  /// [span] of the timeline. The first one starts at 0.46 plus [delay].
  void sparkles(
    Offset center,
    double t, {
    double delay = 0,
    double span = 0.22,
  }) {
    for (final sparkle in _sparkles) {
      final start = sparkle.start + delay;
      final p = stageProgress(t, start, start + span);
      if (p <= 0 || p >= 1) continue;
      final strength = math.sin(math.pi * p);
      final position =
          center +
          Offset(math.cos(sparkle.angle), math.sin(sparkle.angle)) *
              radius *
              sparkle.distance;
      star(
        position,
        5 * strength,
        Paint()..color = light.withValues(alpha: 0.85 * strength),
      );
    }
  }

  /// A four-point star of [size] at [center].
  void star(Offset center, double size, Paint paint) {
    final inner = size * 0.3;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      final r = i.isEven ? size : inner;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path..close(), paint);
  }
}
