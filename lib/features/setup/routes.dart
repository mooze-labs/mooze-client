import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
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
    builder: (context, state) => const NewPinSetupScreen(),
  ),
  GoRoute(
    path: "/setup/pin/confirm",
    builder: (context, state) {
      final pin = state.extra as String?;
      if (pin == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go("/setup/pin/new");
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return ConfirmPinSetupScreen(pin: pin);
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
      );
    },
  ),
  GoRoute(
    path: "/setup/wallet-import-loading",
    builder: (context, state) => const WalletImportLoadingScreen(),
  ),
];
