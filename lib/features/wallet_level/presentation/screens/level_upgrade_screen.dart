import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

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
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _textController;
  late AnimationController _particlesController;

  late Animation<double> _oldLevelScaleAnimation;
  late Animation<double> _newLevelScaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Initialize particles
    _initParticles();

    // Particles animation
    _particlesController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Scale animation for levels
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _oldLevelScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.8,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_scaleController);

    _newLevelScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 1),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 2,
      ),
    ]).animate(_scaleController);

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Glow animation (pulsing effect)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Start animations
    _startAnimations();
  }

  void _initParticles() {
    final random = Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _Particle(
          x: random.nextDouble(),
          y: 0.3 + random.nextDouble() * 0.1,
          vx: (random.nextDouble() - 0.5) * 2,
          vy: random.nextDouble() * 2 + 1,
          color: _getRandomColor(random),
          size: random.nextDouble() * 10 + 5,
        ),
      );
    }
  }

  Color _getRandomColor(Random random) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[random.nextInt(colors.length)];
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _particlesController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return const Color(0xFF8B7355);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFFFD700);
      case 3:
        return const Color(0xFF4169E1);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final levelColor = _getLevelColor(widget.newLevel);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  levelColor.withValues(alpha: 0.2),
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          // Animated particles (confetti effect)
          AnimatedBuilder(
            animation: _particlesController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlesPainter(
                  particles: _particles,
                  progress: _particlesController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Text(
                        'Parabéns!',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Old level (shrinking)
                          AnimatedBuilder(
                            animation: _oldLevelScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _oldLevelScaleAnimation.value,
                                child: Opacity(
                                  opacity: _oldLevelScaleAnimation.value,
                                  child: _buildLevelCircle(
                                    widget.oldLevel,
                                    _getLevelColor(widget.oldLevel),
                                  ),
                                ),
                              );
                            },
                          ),

                          // New level (growing with glow)
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _newLevelScaleAnimation,
                              _glowAnimation,
                            ]),
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _newLevelScaleAnimation.value,
                                child: Opacity(
                                  opacity:
                                      _newLevelScaleAnimation.value > 0
                                          ? 1.0
                                          : 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: levelColor.withValues(
                                            alpha: 0.6 * _glowAnimation.value,
                                          ),
                                          blurRadius: 40 * _glowAnimation.value,
                                          spreadRadius:
                                              10 * _glowAnimation.value,
                                        ),
                                      ],
                                    ),
                                    child: _buildLevelCircle(
                                      widget.newLevel,
                                      levelColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Você subiu de nível!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Do nível ${_getLevels(widget.oldLevel)} para o nível ${_getLevels(widget.newLevel)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Continue assim para desbloquear ainda mais benefícios!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Spacer(),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: PrimaryButton(
                        text: 'Continuar',
                        color: levelColor,
                        onPressed: () {
                          context.pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLevels(level) {
    switch (level) {
      case 0:
        return 'Bronze';
      case 1:
        return 'Prata';
      case 2:
        return 'Ouro';
      case 3:
        return 'Diamante';
      default:
        return 'Bronze';
    }
  }

  Widget _buildLevelCircle(int level, Color color) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Center(
        child: Text(
          _getLevels(level),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  double x; // Position X (0-1)
  double y; // Position Y (0-1)
  final double vx; // Velocity X
  final double vy; // Velocity Y
  final Color color;
  final double size;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final currentY = particle.y + (particle.vy * progress * 0.5);
      final currentX = particle.x + (particle.vx * progress * 0.1);

      if (currentY <= 1.0) {
        final paint =
            Paint()
              ..color = particle.color.withValues(alpha: (1.0 - progress) * 0.9)
              ..style = PaintingStyle.fill;

        final position = Offset(currentX * size.width, currentY * size.height);

        if (particle.size > 7) {
          canvas.drawCircle(position, particle.size / 2, paint);
        } else {
          canvas.save();
          canvas.translate(position.dx, position.dy);
          canvas.rotate(progress * 6.28); // Rotação completa
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            ),
            paint,
          );
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
