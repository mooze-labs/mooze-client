import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/utils/wallet_level_ui_helpers.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

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
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _dropController;
  late AnimationController _textController;

  late Animation<double> _oldLevelScaleAnimation;
  late Animation<double> _newLevelScaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _dropAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _oldLevelScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.95,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 1),
    ]).animate(_scaleController);

    _newLevelScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 2),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ]).animate(_scaleController);

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _dropController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _dropAnimation = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.bounceOut),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _scaleController.forward();
    _dropController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _dropController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final neutralColor = colorScheme.outline;
    final neutralBgColor = colorScheme.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  neutralBgColor.withValues(alpha: 0.3),
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: neutralColor.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 48,
                          color: neutralColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _oldLevelScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _oldLevelScaleAnimation.value,
                                child: Opacity(
                                  opacity: _oldLevelScaleAnimation.value,
                                  child: _buildLevelCircle(
                                    widget.oldLevel,
                                    WalletLevelUiHelpers.getLevelColor(
                                      widget.oldLevel,
                                    ),
                                    textTheme: textTheme,
                                  ),
                                ),
                              );
                            },
                          ),

                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _newLevelScaleAnimation,
                              _dropAnimation,
                              _opacityAnimation,
                            ]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _dropAnimation.value),
                                child: Transform.scale(
                                  scale: _newLevelScaleAnimation.value,
                                  child: Opacity(
                                    opacity:
                                        _newLevelScaleAnimation.value *
                                        _opacityAnimation.value,
                                    child: _buildLevelCircle(
                                      widget.newLevel,
                                      WalletLevelUiHelpers.getLevelColor(
                                        widget.newLevel,
                                      ),
                                      isDowngraded: true,
                                      textTheme: textTheme,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Spacer(),

                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Seu nível foi reduzido',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: neutralColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Do nível ${WalletLevelUiHelpers.getLevelName(widget.oldLevel)} para o nível ${WalletLevelUiHelpers.getLevelName(widget.newLevel)}',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              'Seu nível foi reduzido devido à inatividade. Continue usando o aplicativo para manter ou aumentar seu nível!',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: neutralColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: neutralColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Dica: Use a carteira regularmente para recuperar seus benefícios',
                                    textAlign: TextAlign.center,
                                    style: textTheme.titleSmall?.copyWith(
                                      color: neutralColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: PrimaryButton(
                        text: 'Entendi',
                        color: neutralColor,
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

  Widget _buildLevelCircle(
    int level,
    Color color, {
    bool isDowngraded = false,
    required TextTheme textTheme,
  }) {
    final displayColor = isDowngraded ? color.withValues(alpha: 0.6) : color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          WalletLevelUiHelpers.getLevelIcon(level),
          size: 120,
          color: displayColor,
        ),
        const SizedBox(height: 16),
        Text(
          WalletLevelUiHelpers.getLevelName(level),
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: displayColor,
          ),
        ),
      ],
    );
  }
}
