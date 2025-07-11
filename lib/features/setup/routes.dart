import 'package:go_router/go_router.dart';
import 'presentation/screens.dart';

final setupRoutes = [
  GoRoute(
    path: "/setup/create-wallet/configure-seeds",
    builder: (context, state) => const ConfigureSeedsScreen(),
  ),
  GoRoute(
    path: "/setup/create-wallet/confirm-seeds",
    builder: (context, state) {
      final mnemonic = state.extra as String;
      return ConfirmMnemonicScreen(mnemonic: mnemonic);
    },
  ),
  GoRoute(
    path: "/setup/create-wallet/display-seeds",
    builder: (context, state) {
      final mnemonic = state.extra as String;
      return DisplaySeedsScreen(mnemonic: mnemonic);
    },
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
      final pin = state.extra as String;
      return ConfirmPinSetupScreen(pin: pin);
    },
  ),
];
