import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_face.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The departure of a sent payment, on the stage of the confirmation
/// screen, in the colors of its [StagePalette].
///
/// The coin of the sent asset turns to face you while a paper plane comes
/// out from behind it, sweeps under it, and rises on its other side, slower
/// and slower. Then the plane breaks away: the coin flashes and a shockwave
/// leaves it across the screen, while a flash and a wake of particles mark
/// where the plane left. It climbs into the distance, smaller and smaller,
/// leaving a dotted trace, and stops far up to the right with a sparkle.
/// The scene then stays still: nothing loops.
///
/// [animation] runs from 0 to 1 over [Motion.durationSend]. At 1 the scene
/// rests, so a screen with reduced motion sets it to 1 and nothing plays.
///
/// Three haptics mark the moments while [animation] runs forward:
/// 1. A light impact as the plane comes out from behind the coin
///    ([takeoffAt]).
/// 2. A heavy impact as it breaks away ([boostAt]).
/// 3. A light impact as it gets far, with the sparkle ([arriveAt]).
///
/// The system haptic setting applies to all three.
class SendCelebration extends StatefulWidget {
  const SendCelebration({
    super.key,
    required this.asset,
    required this.animation,
  });

  final Asset asset;
  final Animation<double> animation;

  /// Height of the stage. The shockwave reaches past it.
  static const double height = 300;

  /// Diameter of the coin.
  static const double coinSize = 132;

  /// Progress at which the plane comes out from behind the coin.
  static const double takeoffAt = 0.2;

  /// Progress at which the plane breaks away.
  static const double boostAt = 0.5;

  /// Progress at which the plane stops, far away.
  static const double arriveAt = 0.76;

  /// Where the plane is at [t]: its center, in coin radii from the center
  /// of the coin (y points down); the angle of its nose, clockwise from the
  /// x-axis; its scale, smaller where it is farther; and whether it flies
  /// behind the coin.
  @visibleForTesting
  static ({Offset position, double heading, double scale, bool behind}) planeAt(
    double t,
  ) {
    final share = _flown(t);
    return (
      position: _flight.positionAt(share),
      heading: _flight.headingAt(share),
      scale: _flight.scaleAt(share),
      behind: share < _flight.shareAt(_comesOut),
    );
  }

  @override
  State<SendCelebration> createState() => _SendCelebrationState();
}

class _SendCelebrationState extends State<SendCelebration> with StageHaptics {
  @override
  Animation<double> get stageAnimation => widget.animation;

  @override
  List<StageBeat> get stageBeats => const [
    (at: SendCelebration.takeoffAt, play: HapticFeedback.lightImpact),
    (at: SendCelebration.boostAt, play: HapticFeedback.heavyImpact),
    (at: SendCelebration.arriveAt, play: HapticFeedback.lightImpact),
  ];

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final palette = StagePalette.of(context);
    // The shockwave crosses the whole screen.
    final reach = MediaQuery.sizeOf(context).longestSide;
    const coinSize = SendCelebration.coinSize;

    _StagePainter painter(StageLayer layer) => _StagePainter(
      animation: widget.animation,
      layer: layer,
      brand: brand,
      palette: palette,
      coinRadius: coinSize / 2,
      reach: reach,
    );

    return ExcludeSemantics(
      child: SizedBox(
        height: SendCelebration.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = _StagePainter.centerOf(
              Size(constraints.maxWidth, SendCelebration.height),
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: painter(StageLayer.back)),
                  ),
                ),
                Positioned(
                  left: center.dx - coinSize / 2,
                  top: center.dy - coinSize / 2,
                  child: AnimatedBuilder(
                    animation: widget.animation,
                    builder: (context, child) {
                      final t = widget.animation.value;
                      final grow = Curves.easeOutCubic.transform(
                        stageProgress(t, 0, 0.16),
                      );
                      // It turns to face you while the plane goes around
                      // it, and swells as the plane breaks away.
                      final turn = Curves.easeOutCubic.transform(
                        stageProgress(t, 0, SendCelebration.boostAt),
                      );
                      final swell = math.sin(
                        math.pi * stageProgress(t, 0.46, 0.66),
                      );
                      return Opacity(
                        opacity: stageProgress(t, 0, 0.1),
                        child: Transform.scale(
                          scale:
                              lerpDouble(0.82, 1, grow)! * (1 + 0.06 * swell),
                          child: StageToken(
                            size: coinSize,
                            yaw: lerpDouble(1, 0.42, turn)!,
                            tint: brand,
                            base: palette.base,
                            face: child!,
                          ),
                        ),
                      );
                    },
                    // The face is the same on every frame, so it paints
                    // once and only its transform changes.
                    child: RepaintBoundary(
                      child: StageFace.asset(
                        widget.asset,
                        size: coinSize,
                        tint: brand,
                        palette: palette,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: painter(StageLayer.front)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Points of the flight of the plane, in coin radii from the center of the
/// coin (y points down), with the scale of the plane at each: smaller where
/// it is farther.
const _waypoints = [
  (at: Offset(0.25, -0.55), scale: 0.78),
  (at: Offset(-0.6, -0.62), scale: 0.82),
  (at: Offset(-1.35, -0.05), scale: 0.88),
  (at: Offset(-1.05, 0.72), scale: 0.95),
  (at: Offset(-0.1, 1.08), scale: 1.0),
  (at: Offset(0.95, 0.75), scale: 0.97),
  (at: Offset(1.5, -0.05), scale: 0.92),
  (at: Offset(1.8, -0.9), scale: 0.82),
  (at: Offset(2.25, -1.35), scale: 0.76),
];

/// The waypoint where the plane is out from behind the coin, and the one
/// where it breaks away.
const _comesOut = 2;
const _breaksAway = 6;

/// Progress at which the plane starts to move, behind the coin. The coin is
/// opaque by then, so the plane never shows through it.
const _flightStart = 0.1;

/// The streak behind the plane is the path it flew over this much of the
/// timeline: long when it is fast, gone once it stops.
const _trailSpan = 0.1;

final _flight = _Flight.through(_waypoints);

/// Share of the flight that the plane has flown at [t].
double _flown(double t) {
  final away = _flight.shareAt(_breaksAway);
  if (t < SendCelebration.boostAt) {
    final p = stageProgress(t, _flightStart, SendCelebration.boostAt);
    // Fast under the coin, slower and slower as it rises on the other side.
    return away * (0.8 * Curves.easeInOutSine.transform(p) + 0.2 * p);
  }
  final p = stageProgress(t, SendCelebration.boostAt, SendCelebration.arriveAt);
  return lerpDouble(away, 1, Curves.easeOutCubic.transform(p))!;
}

/// The flight of the plane: a smooth curve through the waypoints, sampled
/// once, and measured so that the plane moves along it by distance.
class _Flight {
  _Flight._(this._points, this._scales, this._shares, this.length);

  factory _Flight.through(List<({Offset at, double scale})> waypoints) {
    final last = waypoints.length - 1;
    // Beyond the ends, the curve goes on as its first and last spans do.
    Offset point(int i) => i < 0
        ? waypoints[0].at * 2 - waypoints[1].at
        : i > last
        ? waypoints[last].at * 2 - waypoints[last - 1].at
        : waypoints[i].at;
    final points = <Offset>[];
    final scales = <double>[];
    for (var i = 0; i < last; i++) {
      for (var j = 0; j < _samples; j++) {
        final u = j / _samples;
        points.add(
          _catmullRom(point(i - 1), point(i), point(i + 1), point(i + 2), u),
        );
        scales.add(lerpDouble(waypoints[i].scale, waypoints[i + 1].scale, u)!);
      }
    }
    points.add(waypoints[last].at);
    scales.add(waypoints[last].scale);
    final distances = [0.0];
    for (var i = 1; i < points.length; i++) {
      distances.add(distances.last + (points[i] - points[i - 1]).distance);
    }
    final length = distances.last;
    return _Flight._(points, scales, [
      for (final distance in distances) distance / length,
    ], length);
  }

  /// Samples per span between two waypoints.
  static const _samples = 24;

  final List<Offset> _points;
  final List<double> _scales;

  /// Share of the flight at each sample, from 0 to 1.
  final List<double> _shares;

  /// Length of the flight, in coin radii.
  final double length;

  /// Share of the flight at the waypoint of [index].
  double shareAt(int index) => _shares[index * _samples];

  Offset positionAt(double share) {
    final (i, f) = _locate(share);
    return Offset.lerp(_points[i], _points[i + 1], f)!;
  }

  double scaleAt(double share) {
    final (i, f) = _locate(share);
    return lerpDouble(_scales[i], _scales[i + 1], f)!;
  }

  double headingAt(double share) {
    final (i, _) = _locate(share);
    return (_points[i + 1] - _points[i]).direction;
  }

  /// The sample before [share], and how far [share] is toward the next.
  (int, double) _locate(double share) {
    final s = share.clamp(0.0, 1.0);
    var low = 0;
    var high = _shares.length - 1;
    while (high - low > 1) {
      final middle = (low + high) ~/ 2;
      if (_shares[middle] <= s) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return (low, (s - _shares[low]) / (_shares[high] - _shares[low]));
  }

  /// A point on the span from [p1] to [p2] of a Catmull-Rom curve, at [u].
  static Offset _catmullRom(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double u,
  ) {
    final u2 = u * u;
    final u3 = u2 * u;
    return (p1 * 2 +
            (p2 - p0) * u +
            (p0 * 2 - p1 * 5 + p2 * 4 - p3) * u2 +
            (p1 * 3 - p0 - p2 * 3 + p3) * u3) *
        0.5;
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter({
    required this.animation,
    required this.layer,
    required this.brand,
    required this.palette,
    required this.coinRadius,
    required this.reach,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final StageLayer layer;
  final Color brand;
  final StagePalette palette;
  final double coinRadius;

  /// Largest radius of the shockwave.
  final double reach;

  /// Center of the coin on a stage of [size].
  static Offset centerOf(Size size) =>
      Offset(size.width / 2, size.height * 0.46);

  /// Length of the plane at its full scale, in coin radii.
  static const _planeLength = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final center = centerOf(size);
    final light = palette.highlight(brand);
    final back = layer == StageLayer.back;
    Offset at(Offset point) => center + point * coinRadius;
    // The plane breaks away from here: the flash and the wake leave this
    // point.
    final away = at(_flight.positionAt(_flight.shareAt(_breaksAway)));

    if (back) {
      // The light behind the coin grows as the plane goes around it, then
      // the ripples on the floor and the dots settle. As the plane breaks
      // away, the coin flashes and a shockwave leaves it.
      final effects =
          StageEffects(canvas, tint: brand, light: light, radius: coinRadius)
            ..glow(
              center,
              stageProgress(t, 0, 0.16) *
                  lerpDouble(
                    0.6,
                    1,
                    stageProgress(t, 0.3, SendCelebration.boostAt),
                  )!,
            )
            ..floor(
              center,
              Curves.easeOut.transform(stageProgress(t, 0.56, 0.88)),
            )
            ..dots(size, stageProgress(t, 0.6, 1))
            ..shockwave(
              center,
              reach,
              stageProgress(t, SendCelebration.boostAt, 0.92),
              1,
            )
            ..shockwave(center, reach, stageProgress(t, 0.58, 1), 0.45);
      if (t >= SendCelebration.boostAt) {
        effects.flash(center, stageProgress(t, SendCelebration.boostAt, 0.66));
      }
    } else {
      _trace(canvas, t, center);
    }
    _trail(canvas, t, center);
    if (!back && t >= SendCelebration.boostAt) _boost(canvas, t, away, light);
    final plane = SendCelebration.planeAt(t);
    if (plane.behind == back) {
      _plane(
        canvas,
        at(plane.position),
        plane.heading,
        plane.scale,
        stageProgress(t, _flightStart, _flightStart + 0.04),
        light,
      );
    }
    if (!back) {
      final effects = StageEffects(
        canvas,
        tint: brand,
        light: light,
        radius: coinRadius,
      )..sparkles(center, t, delay: 0.08, span: 0.16);
      // A sparkle just ahead of the plane as it stops.
      final p = stageProgress(t, SendCelebration.arriveAt, 0.94);
      if (p > 0 && p < 1) {
        final strength = math.sin(math.pi * p);
        final nose =
            at(plane.position) +
            Offset.fromDirection(plane.heading) *
                coinRadius *
                _planeLength *
                plane.scale *
                0.85;
        effects.star(
          nose,
          7 * strength,
          Paint()..color = light.withValues(alpha: 0.9 * strength),
        );
      }
    }
  }

  /// The streak behind the plane, brighter and wider toward it. Each part
  /// is on the layer of where the plane was, behind the coin or in front.
  void _trail(Canvas canvas, double t, Offset center) {
    final head = _flown(t);
    final tail = _flown(t - _trailSpan);
    if (head - tail < 1e-4) return;
    final behindUntil = _flight.shareAt(_comesOut);
    final back = layer == StageLayer.back;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const steps = 32;
    var previous = center + _flight.positionAt(tail) * coinRadius;
    for (var i = 1; i <= steps; i++) {
      final share = lerpDouble(tail, head, i / steps)!;
      final point = center + _flight.positionAt(share) * coinRadius;
      if ((share < behindUntil) == back) {
        final k = i / steps;
        line
          ..strokeWidth = lerpDouble(0.6, 3, k)! * _flight.scaleAt(share)
          ..color = brand.withValues(alpha: 0.85 * k * k);
        canvas.drawLine(previous, point, line);
      }
      previous = point;
    }
  }

  /// The dotted trace the plane leaves once it breaks away. It stays when
  /// the scene rests.
  void _trace(Canvas canvas, double t, Offset center) {
    final from = _flight.shareAt(_breaksAway);
    final head = _flown(t);
    // A dot every 9 px.
    final spacing = 9 / (_flight.length * coinRadius);
    final dot = Paint();
    for (var share = from + spacing; share < head - spacing; share += spacing) {
      final shown = ((head - share) / (spacing * 4)).clamp(0.0, 1.0);
      dot.color = brand.withValues(alpha: 0.55 * shown);
      canvas.drawCircle(
        center + _flight.positionAt(share) * coinRadius,
        1.6 * _flight.scaleAt(share),
        dot,
      );
    }
  }

  /// The flash and the wake where the plane breaks away.
  void _boost(Canvas canvas, double t, Offset away, Color light) {
    final heading = _flight.headingAt(_flight.shareAt(_breaksAway));
    final effects = StageEffects(
      canvas,
      tint: brand,
      light: light,
      radius: coinRadius * 0.4,
    )..flash(away, stageProgress(t, SendCelebration.boostAt, 0.64));
    // Particles thrown back, in a cone behind the plane.
    final distance = coinRadius * 1.2;
    for (final particle in stageParticles) {
      final p = stageProgress(
        t,
        SendCelebration.boostAt + particle.delay * 0.5,
        0.9,
      );
      if (p <= 0 || p >= 1) continue;
      final angle = heading + math.pi + (particle.angle - math.pi) * 0.28;
      final travel =
          distance * particle.speed * Curves.easeOutCubic.transform(p);
      effects.drawParticle(
        away + Offset.fromDirection(angle, travel),
        particle,
        scale: 1 - 0.4 * p,
        strength: math.pow(1 - p, 1.2).toDouble(),
      );
    }
  }

  /// The paper plane at [position], its nose along [heading], at [scale]:
  /// a lit wing above the fold and a shaded one below it, over a soft
  /// light.
  void _plane(
    Canvas canvas,
    Offset position,
    double heading,
    double scale,
    double opacity,
    Color light,
  ) {
    if (opacity == 0) return;
    final length = coinRadius * _planeLength * scale;
    // Flying to the left, it rolls over, so its lit wing stays on top. It
    // is edge-on only while it turns through the vertical.
    final roll = math.cos(heading);
    final flip = roll.sign * (roll.abs() / 0.35).clamp(0.18, 1.0);
    Offset p(double x, double y) =>
        position + Offset(x * length, y * length * flip).rotate(heading);

    canvas.drawCircle(
      position,
      length * 0.9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            brand.withValues(alpha: 0.35 * opacity),
            brand.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: position, radius: length * 0.9)),
    );
    final nose = p(0.5, 0);
    final notch = p(-0.2, 0.05);
    final lit = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(p(-0.5, -0.4).dx, p(-0.5, -0.4).dy)
      ..lineTo(notch.dx, notch.dy)
      ..close();
    final shaded = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(p(-0.4, 0.32).dx, p(-0.4, 0.32).dy)
      ..close();
    canvas
      ..drawPath(
        shaded,
        Paint()
          ..color = brand.withValues(
            alpha: (palette.isDark ? 1 : 0.45) * opacity,
          ),
      )
      ..drawPath(lit, Paint()..color = light.withValues(alpha: opacity));
  }

  @override
  bool shouldRepaint(_StagePainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.layer != layer ||
      oldDelegate.brand != brand ||
      oldDelegate.palette != palette ||
      oldDelegate.coinRadius != coinRadius ||
      oldDelegate.reach != reach;
}

extension on Offset {
  /// This offset turned by [angle], clockwise on screen.
  Offset rotate(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(dx * cos - dy * sin, dx * sin + dy * cos);
  }
}
