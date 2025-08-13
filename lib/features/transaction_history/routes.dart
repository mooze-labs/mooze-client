import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/transactions_bottom_nav_bar.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/peg_history_screen.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/swap_history_screen.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/transaction_history_screen.dart';

final transactionHistoryRoutes = [
  ShellRoute(
    builder: (context, state, child) {
      final currentLocation = state.uri.toString();
      return Scaffold(
        body: child,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: TransactionsBottomNavBar(
          currentIndex: _getIndexFromLocation(currentLocation),
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/transactions-history');
                break;
              case 1:
                context.go('/swaps-history');
                break;
              case 2:
                context.go('/pegs-history');
                break;
            }
          },
        ),
      );
    },
    routes: [
      GoRoute(
        path: '/transactions-history',
        pageBuilder:
            (context, state) =>
                const NoTransitionPage(child: TransactionHistoryScreen()),
      ),
      GoRoute(
        path: '/swaps-history',
        pageBuilder:
            (context, state) =>
                const NoTransitionPage(child: SwapHistoryScreen()),
      ),
      GoRoute(
        path: '/pegs-history',
        pageBuilder:
            (context, state) =>
                const NoTransitionPage(child: PegHistoryScreen()),
      ),
    ],
  ),
];

int _getIndexFromLocation(String location) {
  if (location.startsWith('/transactions-history')) return 0;
  if (location.startsWith('/swaps-history')) return 1;
  if (location.startsWith('/pegs-history')) return 2;
  return 0;
}
