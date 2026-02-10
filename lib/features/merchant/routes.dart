import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_mode_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_mode_exit_screen.dart';

final merchantRoutes = [
  GoRoute(
    path: "/merchant",
    builder: (context, state) {
      final origin = state.extra as String?;
      return MerchantModeScreen(origin: origin);
    },
  ),
  GoRoute(
    path: "/merchant/exit",
    pageBuilder:
        (context, state) => CustomTransitionPage(
          child: const MerchantModeExitScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
];
