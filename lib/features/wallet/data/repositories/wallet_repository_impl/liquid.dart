import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/infra/lwk/wallet.dart';
import 'package:lwk/lwk.dart' as lwk;

class LiquidWallet {
  final LiquidDataSource _datasource;

  LiquidWallet(LiquidDataSource datasource) : _datasource = datasource;

  TaskEither<WalletError, List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final walletTxs = TaskEither.tryCatch(
      () async {
        final transactions = await _datasource.wallet.txs();
        print("Liquid Transactions: ${transactions.length}");
        return transactions;
      },
      (err, _) => WalletError(
        WalletErrorType.connectionError,
        "Falha ao acessar transações",
      ),
    );

    return walletTxs
        .flatMap(
          (txs) => TaskEither<WalletError, Iterable<Transaction>>.right(
            txs.map((tx) => _readTransaction(tx)),
          ),
        )
        .flatMap((transactions) => TaskEither.right(
          _applyFilters(
            transactions,
            asset: asset,
            blockchain: blockchain,
            type: type,
            status: status,
            startDate: startDate,
            endDate: endDate,
          ).toList(),
        ));
  }

  Iterable<Transaction> _applyFilters(
    Iterable<Transaction> transactions, {
    Asset? asset,
    Blockchain? blockchain,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return transactions.where((tx) {
      if (asset != null && tx.asset != asset) return false;
      if (blockchain != null && tx.blockchain != blockchain) return false;
      if (type != null && tx.type != type) return false;
      if (status != null && tx.status != status) return false;
      if (startDate != null &&
          tx.createdAt.millisecondsSinceEpoch < startDate.millisecondsSinceEpoch) return false;
      if (endDate != null &&
          tx.createdAt.millisecondsSinceEpoch > endDate.millisecondsSinceEpoch) return false;
      return true;
    });
  }

  Transaction _readTransaction(lwk.Tx transaction) {
    return Transaction(
      id: transaction.txid,
      amount: transaction.amount,
      blockchain: Blockchain.liquid,
      asset: transaction.asset,
      type: transaction.type,
      status: transaction.status,
      createdAt: transaction.createdAt,
    );
  }
}

extension ToTransaction on lwk.Tx {
  TransactionType get type {
    if ((balances.all((i) => i.value > 0)) || kind == "incoming") {
      return TransactionType.receive;
    }

    if ((balances.all((v) => v.value < 0)) || kind == "outgoing") {
      return TransactionType.send;
    }

    if (kind == "redeposit") {
      return TransactionType.redeposit;
    }

    if ((balances.any((i) => i.value > 0)) &&
        (balances.any((i) => i.value < 0))) {
      return TransactionType.swap;
    }

    return TransactionType.unknown;
  }

  Asset get asset {
    if (balances.length == 1) {
      return Asset.fromId(balances.first.assetId);
    }

    final balance = balances.firstWhere((bal) => bal.assetId != Asset.lbtc.id);
    return Asset.fromId(balance.assetId);
  }

  BigInt get amount {
    if (balances.length == 1) {
      return BigInt.from(balances.first.value);
    }

    final balance = balances.firstWhere((bal) => bal.assetId != Asset.lbtc.id);
    return BigInt.from(balance.value);
  }

  TransactionStatus get status {
    if (height != null) {
      return TransactionStatus.confirmed;
    }

    return TransactionStatus.pending;
  }

  DateTime get createdAt {
    if (timestamp == null) {
      // TODO: Come up with a way to get datetime for unconfirmed transactions.
      return DateTime.now();
    }

    return DateTime.fromMillisecondsSinceEpoch(timestamp!);
  }
}
