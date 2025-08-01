import 'package:flutter/material.dart';

/// Splash screen with logo animation and delayed loader display.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _showLoader = false;

  static const _animationDuration = Duration(milliseconds: 800);
  static const _delayBeforeLoader = Duration(milliseconds: 300);
  static const double _logoWidth = 256.0;
  static const double _logoHeight = 52.0;
  static const double _loaderSize = 25.0;
  static const double _spacingBetweenElements = 24.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  /// Initializes the animation controllers and tweens.
  void _initAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
  }

  /// Starts the logo animation, then triggers the loader display with a delay.
  void _startAnimationSequence() {
    _logoController.forward().whenComplete(() {
      Future.delayed(_delayBeforeLoader, () {
        if (mounted) {
          setState(() => _showLoader = true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogoAnimation(),
            SizedBox(height: _spacingBetweenElements),
            _buildLoader(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoAnimation() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Image.asset(
          'assets/images/logos/mooze-logo.png',
          width: _logoWidth,
          height: _logoHeight,
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: _showLoader
          ? SizedBox(
              width: _loaderSize,
              height: _loaderSize,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFE91E63),
              ),
            )
          : const SizedBox(height: 0),
    );
  }
}