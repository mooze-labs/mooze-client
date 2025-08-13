import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/new_ui_wallet/asset/presentation/screens/asset_screen.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/main_settings_screen.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/swap_screen.dart';
import 'package:mooze_mobile/shared/widgets/bottom_nav_bar/custom_bottom_nav_bar.dart';

import 'presentation/screens/home/home.dart';

final walletRoutes = [
  ShellRoute(
    builder: (context, state, child) {
      final currentLocation = state.uri.toString();
      return Scaffold(
        body: child,
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _getIndexFromLocation(currentLocation),
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/asset');
                break;
              case 2:
                context.go('/pix');
                break;
              case 3:
                context.go('/swap');
                break;
              case 4:
                context.go('/menu');
                break;
            }
          },
        ),
      );
    },
    routes: [
      GoRoute(
        path: '/home',
        pageBuilder:
            (context, state) => NoTransitionPage(
              child: HomeScreen(),
            ),
      ),
      GoRoute(
        path: '/asset',
        pageBuilder:
            (context, state) => NoTransitionPage(child: AssetPage()),
      ),
      GoRoute(
        path: '/pix',
        pageBuilder:
            (context, state) => NoTransitionPage(child: ReceivePixScreen()),
      ),
      GoRoute(
        path: '/swap',
        pageBuilder:
            (context, state) =>
                const NoTransitionPage(child: SwapScreen()),
      ),
      GoRoute(
        path: '/menu',
        pageBuilder:
            (context, state) => const NoTransitionPage(child: MainSettingsScreen()),
      ),
    ],
  ),
];

int _getIndexFromLocation(String location) {
  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/asset')) return 1;
  if (location.startsWith('/pix')) return 2;
  if (location.startsWith('/swap')) return 3;
  if (location.startsWith('/menu')) return 4;
  return 0;
}