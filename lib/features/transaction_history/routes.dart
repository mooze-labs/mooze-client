import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/transaction_detail_screen.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/transaction_history_screen.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';

final transactionHistoryRoutes = [
  GoRoute(
    path: '/transactions-history',
    pageBuilder:
        (context, state) =>
            const NoTransitionPage(child: TransactionHistoryScreen()),
  ),
  GoRoute(
    path: '/transactions-details',
    pageBuilder:
        (context, state) => NoTransitionPage(
          child: TransactionDetailScreen(
            transaction: state.extra as Transaction,
          ),
        ),
  ),
];
