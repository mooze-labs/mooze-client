import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';

part 'transaction_history_provider.g.dart';

class TransactionFilters {
  final Asset? selectedAsset;
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionFilters({this.selectedAsset, this.startDate, this.endDate});

  TransactionFilters copyWith({
    Asset? selectedAsset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionFilters(
      selectedAsset: selectedAsset ?? this.selectedAsset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

final transactionFiltersProvider = StateProvider<TransactionFilters>((ref) {
  return TransactionFilters();
});

final filteredTransactionsProvider = FutureProvider<List<TransactionRecord>>((
  ref,
) async {
  final transactions = await ref.watch(transactionHistoryProvider.future);
  final filters = ref.watch(transactionFiltersProvider);

  return transactions.where((transaction) {
    // Filter by asset if selected
    if (filters.selectedAsset != null) {
      if (transaction.asset != filters.selectedAsset) {
        return false;
      }
    }

    // Filter by date range if selected
    if (filters.startDate != null && transaction.timestamp != null) {
      if (transaction.timestamp!.isBefore(filters.startDate!)) {
        return false;
      }
    }
    if (filters.endDate != null && transaction.timestamp != null) {
      if (transaction.timestamp!.isAfter(filters.endDate!)) {
        return false;
      }
    }

    return true;
  }).toList();
});

@Riverpod(keepAlive: true)
class TransactionHistory extends _$TransactionHistory {
  @override
  Future<List<TransactionRecord>> build() async {
    final liquidTransactions =
        await ref
            .read(liquidWalletNotifierProvider.notifier)
            .getTransactionHistory();

    final bitcoinTransactions =
        await ref
            .read(bitcoinWalletNotifierProvider.notifier)
            .getTransactionHistory();

    return [...liquidTransactions, ...bitcoinTransactions]..sort((a, b) {
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;

      // Sort in descending order (newest first)
      return b.timestamp!.compareTo(a.timestamp!);
    });
  }

  Future<bool> refresh() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(liquidWalletNotifierProvider.notifier).sync();
      final transactions = await build(); // Re-fetches assets after sync
      state = AsyncValue.data(transactions);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}
