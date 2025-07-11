import 'package:go_router/go_router.dart';
import 'presentation/screens.dart';

final setupRoutes = GoRouter(
  routes: [
    GoRoute(
      path: "/setup/create-wallet/configure-seeds",
      builder: (context, state) => const ConfigureSeedsScreen(),
    ),
    GoRoute(
      path: "/setup/create-wallet/confirm-seeds",
      builder: (context, state) => const ConfirmMnemonicScreen(),
    ),
    GoRoute(
      path: "/setup/create-wallet/display-seeds",
      builder: (context, state) => DisplaySeedsScreen(),
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
      builder:
          (context, state) => ConfirmPinSetupScreen(pin: state.extra as String),
    ),
  ],
);
