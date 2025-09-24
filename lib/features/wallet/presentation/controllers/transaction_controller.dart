import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class TransactionController {
  final WalletRepository _wallet;

  TransactionController(WalletRepository wallet) : _wallet = wallet;

  TaskEither<WalletError, List<Transaction>> getLastTransactions(int count) {
    return getTransactions().flatMap(
      (transactions) => TaskEither.right(transactions.take(count).toList()),
    );
  }

  TaskEither<WalletError, List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
  }) {
    return _wallet.getTransactions(
      type: type,
      status: status,
      asset: asset,
      blockchain: blockchain,
    );
  }
}
