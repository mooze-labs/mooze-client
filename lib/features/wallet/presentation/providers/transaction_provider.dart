import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import '../controllers/transaction_controller.dart';

final transactionControllerProvider = FutureProvider<Either<WalletError, TransactionController>>((ref) async {
  final walletRepository = await ref.read(walletRepositoryProvider.future);

  return walletRepository.flatMap((f) => right(TransactionController(f)));
});

final transactionHistoryProvider = FutureProvider<Either<WalletError, List<Transaction>>>((ref) async {
  final transactionController = await ref.read(transactionControllerProvider.future);

  return transactionController.fold(
      (err) async => left(err),
      (c) async => await c.getTransactions().run()
  );
});