import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/biometric_setup_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/verify_pin_screen.dart';
import 'presentation/screens.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/security/secure_screen.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_through_page.dart';

final setupRoutes = [
  GoRoute(
    path: "/setup/create-wallet/configure-seeds",
    builder: (context, state) => const ConfigureSeedsScreen(),
  ),
  // Sensitive: shows recovery words for confirmation. Wrapped in SecureScreen
  // so OS screenshot protection tracks its visibility (see ScreenSecurity).
  GoRoute(
    path: "/setup/create-wallet/confirm-seeds",
    builder: (context, state) => SecureScreen(child: ConfirmMnemonicScreen()),
  ),
  // Sensitive: displays the generated recovery phrase. Reveal gate shows the
  // branded "Screenshot Blocked" notice before exposing the words.
  GoRoute(
    path: "/setup/create-wallet/display-seeds",
    builder: (context, state) => SecureScreen(
      showSecurityNotice: true,
      child: DisplaySeedsScreen(mnemonic: state.extra as String),
    ),
  ),
  // Sensitive: user types/pastes their recovery phrase.
  GoRoute(
    path: "/setup/import-wallet",
    builder: (context, state) =>
        const SecureScreen(child: ImportWalletScreen()),
  ),
  GoRoute(
    path: "/setup/first-access",
    builder: (context, state) => const FirstAccessScreen(),
  ),
  GoRoute(
    path: "/setup/pin/new",
    builder: (context, state) {
      final isChangingPin = state.extra as bool? ?? false;
      return NewPinSetupScreen(isChangingPin: isChangingPin);
    },
  ),
  GoRoute(
    path: "/setup/pin/confirm",
    builder: (context, state) {
      final extra = state.extra;
      String? pin;
      bool isChangingPin = false;

      if (extra is Map<String, dynamic>) {
        pin = extra['pin'] as String?;
        isChangingPin = extra['isChangingPin'] as bool? ?? false;
      } else if (extra is String) {
        pin = extra;
      }

      if (pin == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go("/setup/pin/new");
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return ConfirmPinSetupScreen(pin: pin, isChangingPin: isChangingPin);
    },
  ),
  GoRoute(
    path: "/setup/pin/verify",
    pageBuilder: (context, state) {
      final args = state.extra as VerifyPinArgs?;
      final canGoBack = args?.canGoBack ?? true;
      final screen = VerifyPinScreen(
        onPinConfirmed: args?.onPinConfirmed ?? () {},
        forceAuth: args?.forceAuth ?? false,
        isAppResuming: args?.isAppResuming ?? false,
        canGoBack: canGoBack,
      );
      // A PIN screen without a way back replaces the whole stack, as on
      // launch from the splash. It fades in over the splash instead of
      // sliding in. A PIN step pushed inside a flow keeps the platform
      // transition.
      if (!canGoBack) {
        return fadeThroughPage(context: context, state: state, child: screen);
      }
      return MaterialPage(
        key: state.pageKey,
        name: state.name ?? state.path,
        restorationId: state.pageKey.value,
        child: screen,
      );
    },
  ),
  GoRoute(
    path: "/setup/wallet-import-loading",
    builder: (context, state) => const WalletImportLoadingScreen(),
  ),

  GoRoute(
    path: "/setup/onboarding",
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(
    path: "/setup/biometric",
    builder: (context, state) => const BiometricSetupScreen(),
  ),
];
