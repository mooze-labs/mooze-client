import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/routes.dart';
import 'package:mooze_mobile/features/phone_verification/routes.dart';
import 'package:mooze_mobile/features/settings/routes.dart';
import 'package:mooze_mobile/features/transaction_history/routes.dart';
import 'package:mooze_mobile/features/wallet_level/routes.dart';
import './features/pix/routes.dart';
import './features/setup/routes.dart';
import './features/splash/presentation/screen.dart';
import './features/wallet/routes.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) =>  SplashPage(),
    ),
    ...pixRoutes,
    ...setupRoutes,
    ...walletRoutes,
    ...phoneVerificationRoutes,
    ...settingsRoutes,
    ...transactionHistoryRoutes,
    ...walletLevelsRoutes,
    ...merchantRoutes,
  ],
);

/*
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => SplashScreen()),
    GoRoute(
      path: '/first_access',
      builder: (context, state) => FirstAccessScreen(),
    ),
    GoRoute(
      path: '/create_wallet',
      builder: (context, state) => CreateWalletScreen(),
    ),
    GoRoute(
      path: '/import_wallet',
      builder: (context, state) => ImportWalletScreen(),
    ),
    GoRoute(path: '/wallet', builder: (context, state) => WalletScreen()),
    GoRoute(
      path: '/send_funds',
      builder: (context, state) => SendFundsScreen(),
    ),
    GoRoute(
      path: '/receive_pix',
      builder: (context, state) => ReceivePixScreen(),
    ),
    GoRoute(
      path: '/receive_funds',
      builder: (context, state) => ReceiveFundsScreen(),
    ),
    GoRoute(path: '/swap', builder: (context, state) => SideswapScreen()),
    GoRoute(
      path: '/transaction_history',
      builder: (context, state) => TransactionHistoryScreen(),
    ),
    GoRoute(
      path: '/store_mode',
      builder: (context, state) => StoreHomeScreen(),
    ),
    GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),
    GoRoute(
      path: '/terms-and-conditions',
      builder: (context, state) => TermsAndConditionsScreen(),
    ),
    GoRoute(path: '/input_peg', builder: (context, state) => InputPegScreen()),
  ],
);
*/
