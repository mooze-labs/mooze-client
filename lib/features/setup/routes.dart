import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/verify_pin.dart';
import 'presentation/screens.dart';
import 'package:flutter/material.dart';

final setupRoutes = [
  GoRoute(
    path: "/setup/create-wallet/configure-seeds",
    builder: (context, state) => const ConfigureSeedsScreen(),
  ),
  GoRoute(
    path: "/setup/create-wallet/confirm-seeds",
    builder: (context, state) => ConfirmMnemonicScreen(),
  ),
  GoRoute(
    path: "/setup/create-wallet/display-seeds",
    builder:
        (context, state) => DisplaySeedsScreen(mnemonic: state.extra as String),
  ),
  GoRoute(
    path: "/setup/import-wallet",
    builder: (context, state) => const ImportWalletScreen(),
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
    builder: (context, state) {
      final args = state.extra as VerifyPinArgs?;
      return VerifyPinScreen(
        onPinConfirmed: args?.onPinConfirmed ?? () {},
        forceAuth: args?.forceAuth ?? false,
        isAppResuming: args?.isAppResuming ?? false,
        canGoBack: args?.canGoBack ?? true,
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
];
