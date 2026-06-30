import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/utils/wallet_level_ui_helpers.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class LevelUpgradeScreen extends StatefulWidget {
  final int oldLevel;
  final int newLevel;

  const LevelUpgradeScreen({
    super.key,
    required this.oldLevel,
    required this.newLevel,
  });

  @override
  State<LevelUpgradeScreen> createState() => _LevelUpgradeScreenState();
}

class _LevelUpgradeScreenState extends State<LevelUpgradeScreen>
    with TickerProviderStateMixin {
  late AnimationController _sparklesController;
  late AnimationController _confettiController;
  late AnimationController _ringPulseController;
  late AnimationController _iconController;
  late AnimationController _glowController;
  late AnimationController _contentController;

  late Animation<double> _iconScaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _badgeAnimation;
  late Animation<double> _levelNameAnimation;
  late Animation<double> _transitionRowAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _buttonAnimation;

  final List<_Sparkle> _sparkles = [];
  final List<_ConfettiPiece> _confetti = [];

  @override
  void initState() {
    super.initState();

    _initParticles();

    _sparklesController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _ringPulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _badgeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _levelNameAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );
    _transitionRowAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
    );
    _textAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.55, 0.82, curve: Curves.easeOut),
    );
    _buttonAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  void _initParticles() {
    final random = Random(42);
    final levelColor = WalletLevelUiHelpers.getLevelColor(widget.newLevel);
    final sparkleColors = [Colors.white, Colors.amber.shade200, levelColor];

    for (int i = 0; i < 42; i++) {
      _sparkles.add(
        _Sparkle(
          x: random.nextDouble(),
          size: 3.0 + random.nextDouble() * 5.5,
          speed: 0.3 + random.nextDouble() * 0.7,
          phaseOffset: random.nextDouble(),
          color: sparkleColors[random.nextInt(sparkleColors.length)],
        ),
      );
    }

    final confettiColors = [
      levelColor,
      Colors.amber.shade300,
      Colors.white,
      Colors.pink.shade200,
      Colors.lightBlue.shade200,
      Colors.greenAccent.shade200,
    ];

    for (int i = 0; i < 35; i++) {
      _confetti.add(
        _ConfettiPiece(
          x: random.nextDouble(),
          width: 5 + random.nextDouble() * 8,
          height: 3 + random.nextDouble() * 5,
          speed: 0.15 + random.nextDouble() * 0.35,
          phaseOffset: random.nextDouble(),
          rotationSpeed: (random.nextDouble() - 0.5) * 4,
          color: confettiColors[random.nextInt(confettiColors.length)],
          sway: (random.nextDouble() - 0.5) * 60,
        ),
      );
    }
  }

  Future<void> _startAnimations() async {
    _contentController.forward();

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _iconController.forward();
  }

  @override
  void dispose() {
    _sparklesController.dispose();
    _confettiController.dispose();
    _ringPulseController.dispose();
    _iconController.dispose();
    _glowController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Returns a version of [color] that is always legible against both light and
  /// dark backgrounds. In dark mode the color is used as-is. In light mode the
  /// HSL lightness is clamped to 45 % so that colours like gold (#FFD700,
  /// L ≈ 50 %) don't disappear against a white surface.
  Color _toReadable(Color color, Brightness brightness) {
    if (brightness == Brightness.dark) return color;
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(hsl.lightness.clamp(0.0, 0.45)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;
    final brightness = Theme.of(context).brightness;
    final levelColor = WalletLevelUiHelpers.getLevelColor(widget.newLevel);
    final oldLevelColor = WalletLevelUiHelpers.getLevelColor(widget.oldLevel);
    // Readable variants: darkened in light mode so they contrast against white.
    final readableLevelColor = _toReadable(levelColor, brightness);
    final readableOldLevelColor = _toReadable(oldLevelColor, brightness);

    return Scaffold(
      backgroundColor: context.colors.backgroundColor,
      body: Stack(
        children: [
          // Pulsing background gradient
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 1.3,
                  colors: [
                    levelColor.withValues(
                      alpha: 0.22 + _glowAnimation.value * 0.18,
                    ),
                    levelColor.withValues(alpha: 0.07),
                    context.colors.backgroundColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Sparkle particles
          AnimatedBuilder(
            animation: _sparklesController,
            builder: (context, _) => CustomPaint(
              painter: _SparklesPainter(
                sparkles: _sparkles,
                progress: _sparklesController.value,
              ),
              size: Size.infinite,
            ),
          ),

          // Confetti particles
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) => CustomPaint(
              painter: _ConfettiPainter(
                pieces: _confetti,
                progress: _confettiController.value,
              ),
              size: Size.infinite,
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge
                  FadeTransition(
                    opacity: _badgeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(_badgeAnimation),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: readableLevelColor,
                          ),
                        ),
                        child: Text(
                          '✦  SUBIU DE NÍVEL!  ✦',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Ring pulses + glowing level icon
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withValues(
                              alpha: 0.28 + _glowAnimation.value * 0.38,
                            ),
                            blurRadius: 40 + _glowAnimation.value * 35,
                            spreadRadius: 6 + _glowAnimation.value * 14,
                          ),
                          BoxShadow(
                            color: levelColor.withValues(alpha: 0.12),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding ring pulses
                        AnimatedBuilder(
                          animation: _ringPulseController,
                          builder: (context, _) => CustomPaint(
                            painter: _RingPulsePainter(
                              progress: _ringPulseController.value,
                              color: readableLevelColor,
                            ),
                            child: const SizedBox(width: 200, height: 200),
                          ),
                        ),
                        // Icon with scale-in
                        ScaleTransition(
                          scale: _iconScaleAnimation,
                          child: Icon(
                            WalletLevelUiHelpers.getLevelIcon(widget.newLevel),
                            size: 148,
                            color: readableLevelColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // New level name
                  FadeTransition(
                    opacity: _levelNameAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(_levelNameAnimation),
                      child: Text(
                        WalletLevelUiHelpers.getLevelName(widget.newLevel),
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: readableLevelColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Old → New transition row
                  FadeTransition(
                    opacity: _transitionRowAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          WalletLevelUiHelpers.getLevelIcon(widget.oldLevel),
                          size: 16,
                          color: readableOldLevelColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          WalletLevelUiHelpers.getLevelName(widget.oldLevel),
                          style: textTheme.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: readableLevelColor.withValues(alpha: 0.7),
                          ),
                        ),
                        Icon(
                          WalletLevelUiHelpers.getLevelIcon(widget.newLevel),
                          size: 16,
                          color: readableLevelColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          WalletLevelUiHelpers.getLevelName(widget.newLevel),
                          style: textTheme.bodyMedium?.copyWith(
                            color: readableLevelColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Congratulations text
                  FadeTransition(
                    opacity: _textAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(_textAnimation),
                      child: Column(
                        children: [
                          Text(
                            'Você subiu de nível!',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Continue assim para desbloquear ainda mais benefícios!',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: context.colors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  FadeTransition(
                    opacity: _buttonAnimation,
                    child: PrimaryButton(
                      text: 'Continuar',
                      color: readableLevelColor,
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sparkle data model ──────────────────────────────────────────────────────────

class _Sparkle {
  final double x;
  final double size;
  final double speed;
  final double phaseOffset;
  final Color color;

  const _Sparkle({
    required this.x,
    required this.size,
    required this.speed,
    required this.phaseOffset,
    required this.color,
  });
}

// ── Confetti data model ─────────────────────────────────────────────────────────

class _ConfettiPiece {
  final double x;
  final double width;
  final double height;
  final double speed;
  final double phaseOffset;
  final double rotationSpeed;
  final double sway;
  final Color color;

  const _ConfettiPiece({
    required this.x,
    required this.width,
    required this.height,
    required this.speed,
    required this.phaseOffset,
    required this.rotationSpeed,
    required this.sway,
    required this.color,
  });
}

// ── Sparkles CustomPainter ──────────────────────────────────────────────────────

class _SparklesPainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;

  const _SparklesPainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final t = (progress + s.phaseOffset) % 1.0;

      final opacity =
          t < 0.15
              ? t / 0.15
              : t > 0.7
              ? (1.0 - t) / 0.3
              : 1.0;

      final cx = s.x * size.width;
      final cy = size.height * 0.52 - t * s.speed * size.height * 0.88;

      if (cy < -s.size * 2) continue;

      final paint =
          Paint()
            ..color = s.color.withValues(
              alpha: (opacity * 0.85).clamp(0.0, 1.0),
            )
            ..style = PaintingStyle.fill;

      _drawStar(canvas, Offset(cx, cy), s.size * (1.0 - t * 0.25), paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double outerR, Paint paint) {
    final innerR = outerR * 0.32;
    const n = 4;
    final path = Path();

    for (int i = 0; i < n * 2; i++) {
      final angle = (i * pi / n) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final px = center.dx + cos(angle) * r;
      final py = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklesPainter old) => progress != old.progress;
}

// ── Confetti CustomPainter ──────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  const _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final t = (progress * p.speed + p.phaseOffset) % 1.0;

      final opacity =
          t < 0.1
              ? t / 0.1
              : t > 0.82
              ? (1.0 - t) / 0.18
              : 1.0;

      final cx =
          p.x * size.width + sin(t * pi * 2 + p.phaseOffset * pi) * p.sway;
      final cy = t * (size.height + 40) - 20;
      final rotation = t * pi * 2 * p.rotationSpeed;

      final paint =
          Paint()
            ..color = p.color.withValues(alpha: (opacity * 0.75).clamp(0.0, 1.0))
            ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.width,
            height: p.height,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => progress != old.progress;
}

// ── Ring Pulse CustomPainter ────────────────────────────────────────────────────

class _RingPulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const ringCount = 3;
    final maxRadius = size.shortestSide * 0.65;

    for (int i = 0; i < ringCount; i++) {
      final phase = (progress + i / ringCount) % 1.0;
      final radius = phase * maxRadius;
      final opacity = (1 - phase) * 0.45;

      final paint =
          Paint()
            ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0 * (1 - phase * 0.6);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPulsePainter old) => progress != old.progress;
}
