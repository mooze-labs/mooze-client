import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/transactions_bottom_nav_bar.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/pix_deposit_detail_screen.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/pix_history_screen.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/transaction_detail_screen.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/transaction_history_screen.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/transaction_refund_screen.dart';

final transactionHistoryRoutes = [
  GoRoute(
    path: '/transactions/details',
    pageBuilder: (context, state) {
      final transaction = state.extra as Transaction;
      return NoTransitionPage(
        child: TransactionDetailScreen(transaction: transaction),
      );
    },
  ),
  GoRoute(
    path: '/transactions/refund',
    pageBuilder: (context, state) {
      final transaction = state.extra as Transaction;
      return NoTransitionPage(
        child: TransactionRefundScreen(transaction: transaction),
      );
    },
  ),
  GoRoute(
    path: '/depix/transactions/details',
    pageBuilder: (context, state) {
      final deposit = state.extra as PixDeposit;
      return NoTransitionPage(child: PixDepositDetailScreen(deposit: deposit));
    },
  ),
  ShellRoute(
    builder: (context, state, child) {
      final currentLocation = state.uri.toString();
      return SafeArea(
        child: Scaffold(
          body: child,
          extendBody: true,
          resizeToAvoidBottomInset: false,
          bottomNavigationBar: TransactionsBottomNavBar(
            currentIndex: _getIndexFromLocation(currentLocation),
            onTap: (index) {
              switch (index) {
                case 0:
                  context.pushReplacement('/transactions-history');
                  break;
                case 1:
                  context.pushReplacement('/swaps-history');
                  break;
              }
            },
          ),
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
                const NoTransitionPage(child: PixHistoryScreen()),
      ),
    ],
  ),
];

int _getIndexFromLocation(String location) {
  if (location.startsWith('/transactions-history')) return 0;
  if (location.startsWith('/swaps-history')) return 1;
  return 0;
}
