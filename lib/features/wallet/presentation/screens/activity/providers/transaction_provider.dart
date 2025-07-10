import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/data/providers/wallet_repository_provider.dart';

final transactionProvider = FutureProvider.autoDispose<List<Transaction>>((
  ref,
) async {
  final walletRepository = ref.watch(walletRepositoryProvider);
  final transactions = await walletRepository.getTransactions();
  return transactions;
});
