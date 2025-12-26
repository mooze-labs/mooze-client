import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/key_management/providers/mnemonic_provider.dart';
import '../../../shared/key_management/providers/has_pin_provider.dart';
import '../../../shared/authentication/providers/ensure_auth_session_provider.dart';
import '../../settings/presentation/actions/navigation_action.dart';
import '../../setup/presentation/providers/onboarding_provider.dart';
import '../../merchant/presentation/providers/merchant_mode_provider.dart';
import '../../../routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
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

    _fadeAnimation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
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
  void _handleNavigation(Option<String> mnemonic) async {
    if (kDebugMode) {
      debugPrint(
        "[SplashScreen] Handling navigation, isSome: ${mnemonic.isSome()}",
      );
    }

    // Check if onboarding has been completed
    final onboardingService = ref.read(onboardingServiceProvider);
    final hasCompletedOnboarding =
        await onboardingService.isOnboardingCompleted();

    // Check if was in merchant mode
    final merchantModeService = ref.read(merchantModeServiceProvider);
    final wasInMerchantMode = await merchantModeService.isMerchantModeActive();

    if (kDebugMode) {
      debugPrint("[SplashScreen] Was in merchant mode: $wasInMerchantMode");
    }

    // Use WidgetsBinding to ensure navigation happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        mnemonic.fold(
          () {
            // No mnemonic found - check if needs onboarding
            if (!hasCompletedOnboarding) {
              if (kDebugMode) {
                debugPrint(
                  "[SplashScreen] First time user, redirecting to /setup/onboarding",
                );
              }
              context.go('/setup/onboarding');
            } else {
              if (kDebugMode) {
                debugPrint(
                  "[SplashScreen] No mnemonic found, redirecting to /setup/first-access",
                );
              }
              context.go('/setup/first-access');
            }
          },
          (mnemonicValue) {
            // Mnemonic exists - user already has wallet, mark onboarding as completed
            if (kDebugMode) {
              debugPrint(
                "[SplashScreen] Mnemonic exists, checking PIN status...",
              );
            }
            // Mark onboarding as completed for existing users
            if (!hasCompletedOnboarding) {
              onboardingService.setOnboardingCompleted();
            }

            // If was in merchant mode, require PIN before returning to merchant mode
            if (wasInMerchantMode) {
              if (kDebugMode) {
                debugPrint(
                  "[SplashScreen] Was in merchant mode, requiring PIN...",
                );
              }
              _authenticateForMerchantMode(mnemonicValue);
            } else {
              _checkPinAndNavigate(mnemonicValue);
            }
          },
        );
      }
    });
  }

  /// Checks if PIN exists and navigates accordingly
  void _checkPinAndNavigate(String mnemonic) async {
    if (kDebugMode) {
      debugPrint("[SplashScreen] Checking PIN status asynchronously...");
    }

    try {
      final hasPin = await ref.read(hasPinProvider.future);

      if (kDebugMode) {
        debugPrint("[SplashScreen] PIN check completed, hasPin: $hasPin");
      }

      if (!mounted) return;

      if (hasPin) {
        // Both mnemonic and PIN exist - normal flow: verify PIN
        if (kDebugMode) {
          debugPrint(
            "[SplashScreen] Both mnemonic and PIN exist, verifying PIN...",
          );
        }
        _authenticateAndNavigate(mnemonic);
      } else {
        // Mnemonic exists but PIN doesn't - incomplete setup
        if (kDebugMode) {
          debugPrint(
            "[SplashScreen] Mnemonic exists but PIN doesn't, redirecting to create PIN...",
          );
        }
        context.go('/setup/pin/new');
      }
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint("[SplashScreen] Error checking PIN: $error");
      if (kDebugMode) debugPrint("[SplashScreen] Stack trace: $stackTrace");
      // On error, redirect to first-access for safety
      if (mounted) {
        context.go('/setup/first-access');
      }
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint("[SplashScreen] Error from mnemonicProvider: $error");
    }
    if (kDebugMode) debugPrint("[SplashScreen] Stack trace: $stackTrace");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (kDebugMode) {
          debugPrint(
            "[SplashScreen] Redirecting to /setup/first-access due to error",
          );
        }
        context.go('/setup/first-access');
      }
    });
  }

  void _authenticateAndNavigate(String mnemonic) async {
    if (kDebugMode) {
      debugPrint(
        "[SplashScreen] Starting authentication with session manager...",
      );
    }

    // Navigate to PIN verification screen
    if (!mounted) return;

    final container = ProviderScope.containerOf(context);

    final verifyPinArgs = VerifyPinArgs(
      onPinConfirmed: () async {
        if (kDebugMode) {
          debugPrint("[SplashScreen] PIN confirmed, ensuring auth session...");
        }

        // Invalidate hasPinProvider using container to avoid disposed widget error
        container.invalidate(hasPinProvider);

        try {
          await container.read(ensureAuthSessionProvider.future);
        } catch (e) {
          if (kDebugMode) debugPrint("[SplashScreen] Error ensuring auth: $e");
        }

        // Navigation will be handled by the router
        if (kDebugMode) debugPrint("[SplashScreen] Navigating to /home...");
        rootNavigatorKey.currentContext?.go('/home');
      },
      forceAuth: true,
      canGoBack: false,
    );

    context.go('/setup/pin/verify', extra: verifyPinArgs);
  }

  void _authenticateForMerchantMode(String mnemonic) async {
    if (kDebugMode) {
      debugPrint("[SplashScreen] Authenticating for merchant mode return...");
    }

    if (!mounted) return;

    final container = ProviderScope.containerOf(context);

    final verifyPinArgs = VerifyPinArgs(
      onPinConfirmed: () async {
        if (kDebugMode) {
          debugPrint(
            "[SplashScreen] PIN confirmed, navigating to merchant mode...",
          );
        }

        // Invalidate hasPinProvider
        container.invalidate(hasPinProvider);

        try {
          await container.read(ensureAuthSessionProvider.future);
        } catch (e) {
          if (kDebugMode) {
            debugPrint("[SplashScreen] Error ensuring auth: $e");
          }
        }

        // Navigate to merchant mode
        if (kDebugMode) {
          debugPrint("[SplashScreen] Navigating to merchant mode...");
        }
        rootNavigatorKey.currentContext?.go('/merchant');
      },
      forceAuth: true,
      canGoBack: false,
    );

    context.go('/setup/pin/verify', extra: verifyPinArgs);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the mnemonic provider and handle navigation
    if (_showLoader) {
      if (kDebugMode) {
        debugPrint(
          "[SplashScreen] Loader is shown, watching mnemonicProvider...",
        );
      }

      final currentLocation = GoRouterState.of(context).uri.toString();
      if (currentLocation.startsWith('/setup/')) {
        if (kDebugMode) {
          debugPrint(
            "[SplashScreen] Already in setup route ($currentLocation), skipping navigation",
          );
        }
        return _buildScaffold();
      }

      final mnemonicAsync = ref.watch(mnemonicProvider);

      mnemonicAsync.when(
        data: (mnemonic) {
          if (kDebugMode) {
            debugPrint(
              "[SplashScreen] Data received from mnemonicProvider, isSome: ${mnemonic.isSome()}",
            );
          }
          _handleNavigation(mnemonic);
        },
        loading: () {
          if (kDebugMode) {
            debugPrint("[SplashScreen] mnemonicProvider still loading...");
          }
        },
        error: (error, stackTrace) {
          _handleError(error, stackTrace);
        },
      );
    }

    return _buildScaffold();
  }

  Widget _buildScaffold() {
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
          'assets/logos/logo_primary.svg',
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
      child:
          _showLoader
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
