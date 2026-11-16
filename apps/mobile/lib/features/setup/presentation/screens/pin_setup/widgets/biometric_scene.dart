import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/authentication/services/biometric_service.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_face.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_hero.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// What the biometric seal shows on its face.
enum BiometricKind {
  /// A face in a viewfinder: Face ID, or a face on Android.
  face,

  /// A fingerprint: Touch ID, or the biometrics of Android.
  fingerprint;

  /// The kind of the biometric that the device has enrolled.
  ///
  /// An iPhone reports either a face or a fingerprint. Android mostly
  /// reports only a strength, not the sensor, so its seal shows a
  /// fingerprint unless the device names a face alone.
  static BiometricKind of(BiometricCapabilities capabilities) =>
      capabilities.hasFaceId && !capabilities.hasFingerprint
      ? face
      : fingerprint;
}

/// Where the biometric scene is in its motion.
@immutable
class BiometricMotion {
  const BiometricMotion({
    this.ambient = 1,
    this.scan = 0,
    this.sweep = 0,
    this.success = 0,
    this.shake = 0,
  });

  /// Time since the screen came in, from 0 to 1 over twice
  /// `Motion.durationAmbient`: the seal enters over its first 24%, then
  /// sways, and rests at 1.
  final double ambient;

  /// How much the seal scans, from 0 to 1: it rises while the system
  /// prompt is up and falls once it closes.
  final double scan;

  /// Where the scan beam is in its sweep, from 0 to 1: down the face and
  /// back up.
  final double sweep;

  /// The success, from 0 to 1 over `Motion.durationBiometricSuccess`.
  final double success;

  /// A failure, from 0 to 1 over `Motion.durationEmphasis`.
  final double shake;

  /// The entrance of the seal, from 0 to 1.
  double get entrance => stageProgress(ambient, 0, 0.24);

  /// A slow sway that rises and falls back to 0.
  double get drift => math.sin(math.pi * ambient);
}

/// The art of the screen that turns on biometrics: a seal of the stage kit
/// with the biometric of the device on its face, which reacts to the state
/// of the system prompt.
///
/// - **Entrance**: the seal grows in, the light comes up, a ring appears,
///   and the seal sways for a few seconds, then rests.
/// - **Scan**: while the system prompt is up, the ridges dim and a beam
///   sweeps the face, lighting the ridges it crosses. On iOS the prompt
///   sits over the middle of the screen with its own animation, so the
///   beam stays quiet there; on Android the prompt is a sheet at the
///   bottom, and the beam shows in full above it.
/// - **Failure**: a short shake while the ridges dim.
/// - **Success**, over [BiometricMotion.success]:
///
/// | Success      | What happens                                         |
/// |--------------|------------------------------------------------------|
/// | 0 → 0.15     | Every ridge lights up; the beam fades.               |
/// | 0.12 → 0.28  | The ridges give way to a check that draws itself.    |
/// | **0.22**     | **Peak**: flash, shockwave, burst, a medium haptic.  |
/// | 0.3          | The caption tells that biometrics are on.            |
/// | 0.5 → 0.66   | The seal turns, faster and faster.                   |
/// | **0.66**     | **Edge-on**: its face becomes the Mooze coin. A      |
/// |              | light haptic.                                        |
/// | 0.66 → 0.84  | The turn slows to rest at the yaw of the coin of the |
/// |              | opening of the wallet, which it then flies into (see |
/// |              | [StageHero.moozeCoin]).                              |
///
/// It is decorative: the caption of the screen tells the state.
class BiometricScene extends StatelessWidget {
  const BiometricScene({super.key, required this.kind, required this.motion});

  final BiometricKind kind;
  final BiometricMotion motion;

  /// Height of the stage. The shockwave reaches past it.
  static const double height = 240;

  /// Diameter of the seal.
  static const double sealSize = 124;

  /// Success at which the check appears with the flash: the peak.
  static const double peakAt = 0.22;

  /// Success after which the caption tells that biometrics are on.
  static const double revealAt = 0.3;

  /// Success at which the seal is edge-on and becomes the Mooze coin.
  static const double edgeOnAt = 0.66;

  /// Success at which the seal rests as the Mooze coin.
  static const double restAt = 0.84;

  /// Yaw of the seal at rest: the yaw of the Mooze coin at the start of
  /// the opening of the wallet.
  static const double restYaw = 0.3;

  static const _moozeGlyph = 'assets/images/onboarding/mooze_m.svg';

  /// Where the seal is in [motion]: its [turn], before it is folded into a
  /// yaw; its sideways [dx] while it shakes; its [scale] and [opacity]; and
  /// whether it [showsCoin], the Mooze coin, rather than the biometric.
  ///
  /// The turn speeds up to edge-on and slows down after it, in two halves,
  /// so edge-on falls at [edgeOnAt] wherever the sway stopped.
  @visibleForTesting
  static ({
    double turn,
    double dx,
    double scale,
    double opacity,
    bool showsCoin,
  })
  sealAt(BiometricMotion motion) {
    final s = motion.success;
    final sway = restYaw + 0.12 * motion.drift;
    final turn = s < edgeOnAt
        ? lerpDouble(
            sway,
            math.pi / 2,
            Curves.easeInSine.transform(stageProgress(s, 0.5, edgeOnAt)),
          )!
        : lerpDouble(
            math.pi / 2,
            math.pi + restYaw,
            Curves.easeOutSine.transform(stageProgress(s, edgeOnAt, restAt)),
          )!;
    final shake = motion.shake;
    final dx = shake <= 0 || shake >= 1
        ? 0.0
        : 10 * math.sin(6 * math.pi * shake) * (1 - shake);
    final grow = Curves.easeOutBack.transform(
      stageProgress(motion.entrance, 0, 0.5),
    );
    final swell = math.sin(math.pi * stageProgress(s, 0.16, 0.36));
    return (
      turn: turn,
      dx: dx,
      scale: lerpDouble(0.82, 1, grow)! * (1 + 0.06 * swell),
      opacity: stageProgress(motion.entrance, 0, 0.25),
      showsCoin: s >= edgeOnAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.primaryColor;
    final palette = StagePalette.of(context);
    final reach = MediaQuery.sizeOf(context).longestSide;
    // The system prompt of iOS covers the middle of the screen with its
    // own animation: the beam stays quiet behind it.
    final scanPeak = Theme.of(context).platform == TargetPlatform.iOS
        ? 0.6
        : 1.0;
    final seal = sealAt(motion);
    final m = motion;
    final s = m.success;
    final e = m.entrance;
    final scan = m.scan * scanPeak;
    const radius = sealSize / 2;

    StageEffects effects(Canvas canvas) => StageEffects(
      canvas,
      tint: brand,
      light: palette.highlight(brand),
      radius: radius,
    );
    final ring = stageRings[1];
    final ringAppear = Curves.easeOut.transform(stageProgress(e, 0.2, 0.7));
    final ringOrbit = 0.4 * m.ambient + 0.6 * Curves.easeOutCubic.transform(s);

    final look = _GlyphLook(
      // While the seal scans, its ridges dim, and the beam lights them.
      ridges:
          lerpDouble(
            lerpDouble(0.85, 0.3, scan)!,
            1,
            Curves.easeOut.transform(stageProgress(s, 0, 0.15)),
          )! *
          (1 - 0.5 * math.sin(math.pi * m.shake)),
      beam: scan * (1 - stageProgress(s, 0, 0.12)),
      beamY: 0.5 - 0.5 * math.cos(2 * math.pi * m.sweep),
      check: Curves.easeInOutCubic.transform(stageProgress(s, 0.12, 0.28)),
    );
    final faces = [
      RepaintBoundary(
        child: StageFace(
          size: sealSize,
          tint: brand,
          palette: palette,
          glyph: (color) => _BiometricGlyph(
            kind: kind,
            color: color,
            look: look,
            size: sealSize * _GlyphPainter._glyphShare,
          ),
        ),
      ),
      RepaintBoundary(
        child: StageFace(
          size: sealSize,
          tint: brand,
          palette: palette,
          glyph: (color) => SvgPicture.asset(
            _moozeGlyph,
            width: sealSize * 0.5,
            height: sealSize * 0.5,
            colorMapper: TwoToneGlyphColors(color),
          ),
        ),
      ),
    ];

    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            StagePaintLayer((canvas, size) {
              final center = size.center(Offset(seal.dx, 0));
              final peak = math.sin(math.pi * stageProgress(s, 0.18, 0.6));
              effects(canvas)
                ..glow(
                  center,
                  math.min(1, 0.55 * stageProgress(e, 0, 0.5) + 0.25 * scan) +
                      0.45 * peak,
                )
                ..dots(size, 0.5 * stageProgress(e, 0.4, 1))
                ..floor(
                  center,
                  0.6 * Curves.easeOut.transform(stageProgress(e, 0.4, 0.9)),
                )
                ..ring(
                  center,
                  ring,
                  StageLayer.back,
                  appear: ringAppear,
                  orbit: ringOrbit,
                );
              if (s >= peakAt && s < 1) {
                effects(canvas)
                  ..shockwave(center, reach, stageProgress(s, peakAt, 0.75), 1)
                  ..flash(center, stageProgress(s, peakAt, peakAt + 0.18))
                  ..burst(center, s, start: peakAt, end: 0.85);
              }
            }),
            Transform.translate(
              offset: Offset(seal.dx, 0),
              child: Opacity(
                opacity: seal.opacity,
                child: Transform.scale(
                  scale: seal.scale,
                  // Once it shows the Mooze coin, it flies on into the
                  // opening of the wallet; before, it stays here.
                  child: HeroMode(
                    enabled: seal.showsCoin,
                    child: StageHero(
                      tag: StageHero.moozeCoin,
                      child: StageToken(
                        size: sealSize,
                        yaw: StageToken.faceYaw(seal.turn),
                        tint: brand,
                        base: palette.base,
                        // It turns past edge-on, so it turns around its
                        // middle.
                        centered: true,
                        // Both faces are built, so the coin shows at once
                        // at edge-on.
                        face: IndexedStack(
                          index: seal.showsCoin ? 1 : 0,
                          children: faces,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            StagePaintLayer((canvas, size) {
              final center = size.center(Offset(seal.dx, 0));
              effects(canvas)
                ..ring(
                  center,
                  ring,
                  StageLayer.front,
                  appear: ringAppear,
                  orbit: ringOrbit,
                )
                ..sparkles(center, s);
            }),
          ],
        ),
      ),
    );
  }
}

/// How the glyph of the seal looks at a moment.
@immutable
class _GlyphLook {
  const _GlyphLook({
    required this.ridges,
    required this.beam,
    required this.beamY,
    required this.check,
  });

  /// Light of the ridges, from 0 to 1.
  final double ridges;

  /// Light of the scan beam, from 0 to 1.
  final double beam;

  /// Height of the beam, from 0 at the top of the glyph to 1 at its
  /// bottom.
  final double beamY;

  /// How far the ridges have given way to the check, from 0 to 1.
  final double check;

  @override
  bool operator ==(Object other) =>
      other is _GlyphLook &&
      other.ridges == ridges &&
      other.beam == beam &&
      other.beamY == beamY &&
      other.check == check;

  @override
  int get hashCode => Object.hash(ridges, beam, beamY, check);
}

/// The biometric glyph of the seal, [size] wide, in [color].
class _BiometricGlyph extends StatelessWidget {
  const _BiometricGlyph({
    required this.kind,
    required this.color,
    required this.look,
    required this.size,
  });

  final BiometricKind kind;
  final Color color;
  final _GlyphLook look;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _GlyphPainter(kind: kind, color: color, look: look),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.kind,
    required this.color,
    required this.look,
  });

  final BiometricKind kind;
  final Color color;
  final _GlyphLook look;

  /// Share of the width of the face that the glyph takes.
  static const _glyphShare = 0.56;

  /// The ridges of the fingerprint, on a unit square: arcs over a common
  /// center, each with a leg down on each side, of different lengths, so
  /// the lines break as the ridges of a finger do.
  static const _ridges = [
    (radius: 0.08, left: 0.16, right: 0.04),
    (radius: 0.16, left: 0.24, right: 0.12),
    (radius: 0.24, left: 0.18, right: 0.26),
    (radius: 0.32, left: 0.08, right: 0.2),
  ];

  static Path _fingerprint(double d) {
    final path = Path();
    final center = Offset(0.5, 0.52) * d;
    for (final ridge in _ridges) {
      final r = ridge.radius * d;
      path
        ..moveTo(center.dx - r, center.dy + ridge.left * d)
        ..lineTo(center.dx - r, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: r),
          math.pi,
          math.pi,
          false,
        )
        ..lineTo(center.dx + r, center.dy + ridge.right * d);
    }
    // The outer ridge shows only over the top.
    path.addArc(
      Rect.fromCircle(center: center, radius: 0.4 * d),
      1.15 * math.pi,
      0.7 * math.pi,
    );
    return path;
  }

  /// A face in the four corners of a viewfinder: eyes and a smile. It is
  /// drawn for the app, not taken from a system symbol.
  static Path _face(double d) {
    const m = 0.12;
    const corner = 0.12;
    const arm = 0.12;
    final path = Path();
    for (final (x, y) in [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]) {
      // Each corner, from the end of its vertical arm to the end of its
      // horizontal one.
      final sx = x == 0 ? 1.0 : -1.0;
      final sy = y == 0 ? 1.0 : -1.0;
      final ox = x == 0 ? m : 1 - m;
      final oy = y == 0 ? m : 1 - m;
      path
        ..moveTo(ox * d, (oy + sy * (corner + arm)) * d)
        ..lineTo(ox * d, (oy + sy * corner) * d)
        ..arcToPoint(
          Offset(ox + sx * corner, oy) * d,
          radius: Radius.circular(corner * d),
          clockwise: sx * sy > 0,
        )
        ..lineTo((ox + sx * (corner + arm)) * d, oy * d);
    }
    for (final x in [0.38, 0.62]) {
      path
        ..moveTo(x * d, 0.38 * d)
        ..lineTo(x * d, 0.46 * d);
    }
    path.addArc(
      Rect.fromCircle(center: Offset(0.5, 0.5) * d, radius: 0.17 * d),
      0.22 * math.pi,
      0.56 * math.pi,
    );
    return path;
  }

  static Path _check(double d) => Path()
    ..moveTo(0.27 * d, 0.53 * d)
    ..lineTo(0.44 * d, 0.69 * d)
    ..lineTo(0.75 * d, 0.36 * d);

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final glyph = kind == BiometricKind.face ? _face(d) : _fingerprint(d);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = d * 0.06;
    final shown = 1 - look.check;

    if (shown > 0) {
      canvas.drawPath(
        glyph,
        stroke..color = color.withValues(alpha: look.ridges * shown),
      );
    }
    if (look.beam > 0 && shown > 0) {
      final light = look.beam * shown;
      // The beam sweeps the whole face, past the glyph: the glyph takes
      // [_glyphShare] of the face.
      final reach = 0.5 / _glyphShare;
      final y = (0.5 + (look.beamY - 0.5) * 2 * reach * 0.86) * d;
      // The ridges near the beam light up.
      final box = Rect.fromLTWH(0, 0, d, d);
      canvas.drawPath(
        glyph,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = d * 0.06
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: light),
              color.withValues(alpha: 0),
            ],
            stops: [
              (y / d - 0.18).clamp(0.0, 1.0),
              (y / d).clamp(0.0, 1.0),
              (y / d + 0.18).clamp(0.0, 1.0),
            ],
          ).createShader(box),
      );
      // The beam, a line in a soft band of light, kept within the face.
      canvas
        ..save()
        ..clipPath(
          Path()..addOval(
            Rect.fromCircle(center: box.center, radius: reach * d * 0.92),
          ),
        );
      final span = Rect.fromLTRB(
        0.5 * d - reach * d,
        y - 0.14 * d,
        0.5 * d + reach * d,
        y + 0.14 * d,
      );
      canvas.drawRect(
        span,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: 0.22 * light),
              color.withValues(alpha: 0),
            ],
          ).createShader(span),
      );
      final line = Rect.fromLTRB(span.left, y - 1, span.right, y + 1);
      canvas
        ..drawRect(
          line,
          Paint()
            ..shader = LinearGradient(
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: light),
                color.withValues(alpha: 0),
              ],
            ).createShader(line),
        )
        ..restore();
    }
    if (look.check > 0) {
      // The check draws itself, from its short stroke to its long one.
      final check = _check(d).computeMetrics().single;
      canvas.drawPath(
        check.extractPath(0, check.length * look.check),
        stroke
          ..strokeWidth = d * 0.09
          ..color = color.withValues(alpha: math.min(1, look.check * 3)),
      );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.look != look;
}
