import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/level_downgrade_screen.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/level_upgrade_screen.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/wallet_levels_screen.dart';

final walletLevelsRoutes = [
  GoRoute(
    path: "/wallet-levels",
    builder: (context, state) => const WalletLevelsScreen(),
  ),
  GoRoute(
    path: "/level-upgrade",
    pageBuilder: (context, state) {
      final oldLevel = state.uri.queryParameters['oldLevel'];
      final newLevel = state.uri.queryParameters['newLevel'];

      return CustomTransitionPage(
        key: state.pageKey,
        child: LevelUpgradeScreen(
          oldLevel: int.parse(oldLevel ?? '1'),
          newLevel: int.parse(newLevel ?? '2'),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      );
    },
  ),
  GoRoute(
    path: "/level-downgrade",
    pageBuilder: (context, state) {
      final oldLevel = state.uri.queryParameters['oldLevel'];
      final newLevel = state.uri.queryParameters['newLevel'];

      return CustomTransitionPage(
        key: state.pageKey,
        child: LevelDowngradeScreen(
          oldLevel: int.parse(oldLevel ?? '2'),
          newLevel: int.parse(newLevel ?? '1'),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      );
    },
  ),
];
