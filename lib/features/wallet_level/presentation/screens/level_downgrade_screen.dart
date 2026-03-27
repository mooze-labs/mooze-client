import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/utils/wallet_level_ui_helpers.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class LevelDowngradeScreen extends StatefulWidget {
  final int oldLevel;
  final int newLevel;

  const LevelDowngradeScreen({
    super.key,
    required this.oldLevel,
    required this.newLevel,
  });

  @override
  State<LevelDowngradeScreen> createState() => _LevelDowngradeScreenState();
}

class _LevelDowngradeScreenState extends State<LevelDowngradeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _particlesController;
  late AnimationController _shakeController;
  late AnimationController _contentController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _shakeAnimation;

  late Animation<double> _badgeAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _transitionRowAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _tipAnimation;
  late Animation<double> _buttonAnimation;

  final List<_FallingParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    _initParticles();

    _particlesController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    );

    // Damped oscillation for the shake: translates to a sine wave that decays
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _badgeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
    );
    _iconAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.15, 0.48, curve: Curves.easeOut),
    );
    _transitionRowAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.38, 0.60, curve: Curves.easeOut),
    );
    _textAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.50, 0.72, curve: Curves.easeOut),
    );
    _tipAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.62, 0.84, curve: Curves.easeOut),
    );
    _buttonAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.76, 1.0, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  void _initParticles() {
    final random = Random(13);
    for (int i = 0; i < 28; i++) {
      _particles.add(
        _FallingParticle(
          x: random.nextDouble(),
          radius: 1.2 + random.nextDouble() * 2.8,
          speed: 0.12 + random.nextDouble() * 0.28,
          phaseOffset: random.nextDouble(),
          opacity: 0.08 + random.nextDouble() * 0.18,
          sway: (random.nextDouble() - 0.5) * 30,
        ),
      );
    }
  }

  Future<void> _startAnimations() async {
    _contentController.forward();
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    _shakeController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _particlesController.dispose();
    _shakeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final neutralColor = colorScheme.outline;
    final oldLevelColor = WalletLevelUiHelpers.getLevelColor(widget.oldLevel);
    final newLevelColor = WalletLevelUiHelpers.getLevelColor(widget.newLevel);

    return Scaffold(
      backgroundColor: context.colors.backgroundColor,
      body: Stack(
        children: [
          // Muted pulsing background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder:
                (context, _) => Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 1.1,
                      colors: [
                        neutralColor.withValues(
                          alpha: 0.05 + _backgroundAnimation.value * 0.05,
                        ),
                        neutralColor.withValues(alpha: 0.02),
                        context.colors.backgroundColor,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
          ),

          // Falling particles
          AnimatedBuilder(
            animation: _particlesController,
            builder:
                (context, _) => CustomPaint(
                  painter: _FallingParticlesPainter(
                    particles: _particles,
                    progress: _particlesController.value,
                    color: neutralColor,
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
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          '↓  NÍVEL REDUZIDO  ↓',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Level icon with shake + glow
                  FadeTransition(
                    opacity: _iconAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(_iconAnimation),
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          // Decaying sine oscillation — horizontal shake
                          final decay = 1.0 - _shakeAnimation.value;
                          final dx =
                              sin(_shakeAnimation.value * pi * 6) * 12 * decay;
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: child,
                          );
                        },
                        child: AnimatedBuilder(
                          animation: _backgroundAnimation,
                          builder:
                              (context, child) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: neutralColor.withValues(
                                        alpha:
                                            0.06 +
                                            _backgroundAnimation.value * 0.06,
                                      ),
                                      blurRadius: 48,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: child,
                              ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // New (lower) level icon
                              Icon(
                                WalletLevelUiHelpers.getLevelIcon(
                                  widget.newLevel,
                                ),
                                size: 112,
                                color: newLevelColor.withValues(alpha: 0.55),
                              ),
                              // Downward arrow badge
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: context.colors.surfaceColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: neutralColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 18,
                                    // color: neutralColor.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Old → New transition row
                  FadeTransition(
                    opacity: _transitionRowAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          WalletLevelUiHelpers.getLevelIcon(widget.oldLevel),
                          size: 15,
                          color: oldLevelColor.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          WalletLevelUiHelpers.getLevelName(widget.oldLevel),
                          style: textTheme.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: context.colors.textSecondary
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: neutralColor.withValues(alpha: 0.45),
                          ),
                        ),
                        Icon(
                          WalletLevelUiHelpers.getLevelIcon(widget.newLevel),
                          size: 15,
                          color: newLevelColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          WalletLevelUiHelpers.getLevelName(widget.newLevel),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Message block
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
                            'Seu nível foi reduzido',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Isso acontece quando a carteira fica inativa por um tempo. Mas não se preocupe — você pode recuperar o nível usando o app.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tip card
                  FadeTransition(
                    opacity: _tipAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_tipAnimation),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dica: Use a carteira regularmente para recuperar seus benefícios e subir de nível novamente.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  FadeTransition(
                    opacity: _buttonAnimation,
                    child: PrimaryButton(
                      text: 'Entendi',
                      color: neutralColor,
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

// ── Falling particle data model ─────────────────────────────────────────────────

class _FallingParticle {
  final double x;
  final double radius;
  final double speed;
  final double phaseOffset;
  final double opacity;
  final double sway;

  const _FallingParticle({
    required this.x,
    required this.radius,
    required this.speed,
    required this.phaseOffset,
    required this.opacity,
    required this.sway,
  });
}

// ── Falling particles CustomPainter ────────────────────────────────────────────

class _FallingParticlesPainter extends CustomPainter {
  final List<_FallingParticle> particles;
  final double progress;
  final Color color;

  const _FallingParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phaseOffset) % 1.0;

      final alpha =
          t < 0.08
              ? t / 0.08 * p.opacity
              : t > 0.88
              ? (1.0 - t) / 0.12 * p.opacity
              : p.opacity;

      final cx =
          p.x * size.width + sin(t * pi * 2 + p.phaseOffset * 2 * pi) * p.sway;
      final cy = t * (size.height + p.radius * 2) - p.radius;

      final paint =
          Paint()
            ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(cx, cy), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_FallingParticlesPainter old) => progress != old.progress;
}
