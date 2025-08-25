import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/routes.dart';
import 'package:mooze_mobile/features/phone_verification/routes.dart';
import 'package:mooze_mobile/features/pix/routes.dart';
import 'package:mooze_mobile/features/settings/routes.dart';
import 'package:mooze_mobile/features/transaction_history/routes.dart';
import 'package:mooze_mobile/features/wallet/routes.dart';
import 'package:mooze_mobile/features/wallet_level/routes.dart';
import './features/setup/routes.dart';
import 'features/splash/presentation/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => SplashScreen()),
    ...setupRoutes,
    ...walletRoutes,
    ...phoneVerificationRoutes,
    ...transactionHistoryRoutes,
    ...pixRoutes,
    ...walletLevelsRoutes,
    ...settingsRoutes,
    ...merchantRoutes,
  ],
);
