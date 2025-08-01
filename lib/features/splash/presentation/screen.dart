import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/key_management/providers/mnemonic_provider.dart';

/// Splash screen with logo animation and delayed loader display.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
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

  /// Handles navigation based on mnemonic state
  void _handleNavigation(Option<String> mnemonic) {
    if (kDebugMode) debugPrint("[SplashScreen] Handling navigation, isSome: ${mnemonic.isSome()}");
    
    // Use WidgetsBinding to ensure navigation happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (mnemonic.isSome()) {
          if (kDebugMode) debugPrint("[SplashScreen] Mnemonic exists, redirecting to /wallet");
          context.go('/wallet');
        } else {
          if (kDebugMode) debugPrint("[SplashScreen] No mnemonic found, redirecting to /setup/first-access");
          context.go('/setup/first-access');
        }
      }
    });
  }

  /// Handles errors and navigates to setup
  void _handleError(Object error, StackTrace stackTrace) {
    if (kDebugMode) debugPrint("[SplashScreen] Error from mnemonicProvider: $error");
    if (kDebugMode) debugPrint("[SplashScreen] Stack trace: $stackTrace");
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (kDebugMode) debugPrint("[SplashScreen] Redirecting to /setup/first-access due to error");
        context.go('/setup/first-access');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the mnemonic provider and handle navigation
    if (_showLoader) {
      if (kDebugMode) debugPrint("[SplashScreen] Loader is shown, watching mnemonicProvider...");
      final mnemonicAsync = ref.watch(mnemonicProvider);
      
      mnemonicAsync.when(
        data: (mnemonic) {
          if (kDebugMode) debugPrint("[SplashScreen] Data received from mnemonicProvider, isSome: ${mnemonic.isSome()}");
          _handleNavigation(mnemonic);
        },
        loading: () {
          if (kDebugMode) debugPrint("[SplashScreen] mnemonicProvider still loading...");
        },
        error: (error, stackTrace) {
          _handleError(error, stackTrace);
        },
      );
    }

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
        child: SvgPicture.asset(
          'assets/new_ui_wallet/assets/logos/logo_primary.svg',
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
