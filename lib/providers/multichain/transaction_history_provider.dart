import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/models/transaction.dart';

part 'transaction_history_provider.g.dart';

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
