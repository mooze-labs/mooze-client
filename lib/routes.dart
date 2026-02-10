import 'package:flutter/material.dart';
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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder:
          (context, state) => CustomTransitionPage(
            child: SplashScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
    ),
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
