import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/address_explorer/routes.dart';
import 'package:mooze_mobile/features/favorite_payers/routes.dart';
import 'package:mooze_mobile/features/merchant/routes.dart';
import 'package:mooze_mobile/features/pix/routes.dart';
import 'package:mooze_mobile/features/settings/routes.dart';
import 'package:mooze_mobile/features/transaction_history/routes.dart';
import 'package:mooze_mobile/features/wallet/routes.dart';
import 'package:mooze_mobile/features/wallet_level/routes.dart';
import 'package:mooze_mobile/shared/deep_links/pending_payment_link.dart';
import './features/setup/routes.dart';
import 'features/splash/presentation/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Last location that resolved to a real route. Used to return the user to
/// where they were after an incoming deep link is captured.
String? _lastGoodLocation;

void _trackLocation() {
  final config = router.routerDelegate.currentConfiguration;
  if (!config.isError) _lastGoodLocation = config.uri.toString();
}

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  // Payment URIs (`bitcoin:`, `liquidnetwork:`) arrive here as unmatched
  // routes, both on cold start (as the platform initial route) and while
  // running. Capture them and continue to the last good location; the home
  // screen opens the send flow once the wallet is ready. Any other unknown
  // location also falls back instead of showing a dead error page.
  onException: (context, state, router) {
    PendingPaymentLink.tryCapture(state.uri);
    router.go(_lastGoodLocation ?? '/splash');
  },
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
    ...transactionHistoryRoutes,
    ...pixRoutes,
    ...walletLevelsRoutes,
    ...settingsRoutes,
    ...merchantRoutes,
    ...addressExplorerRoutes,
    ...favoritePayersRoutes,
  ],
)..routerDelegate.addListener(_trackLocation);
