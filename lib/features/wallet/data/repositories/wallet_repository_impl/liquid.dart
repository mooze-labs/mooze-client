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
        final rawTxs = await _datasource.wallet.txs();
        return rawTxs;
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
        .flatMap(
          (transactions) => TaskEither.right(
            _applyFilters(
              transactions,
              asset: asset,
              blockchain: blockchain,
              type: type,
              status: status,
              startDate: startDate,
              endDate: endDate,
            ).toList(),
          ),
        );
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
          tx.createdAt.millisecondsSinceEpoch <=
              startDate.microsecondsSinceEpoch)
        return false;
      if (endDate != null &&
          tx.createdAt.millisecondsSinceEpoch >= endDate.microsecondsSinceEpoch)
        return false;
      return true;
    });
  }

  Transaction _readTransaction(lwk.Tx transaction) {
    Asset? fromAsset;
    Asset? toAsset;
    BigInt? sentAmount;
    BigInt? receivedAmount;

    final positiveBalances =
        transaction.balances.where((b) => b.value > 0).toList();
    final negativeBalances =
        transaction.balances.where((b) => b.value < 0).toList();

    final hasMultipleAssets =
        positiveBalances.isNotEmpty && negativeBalances.isNotEmpty;
    final hasNonLbtcPositive = positiveBalances.any(
      (b) => b.assetId != Asset.lbtc.id,
    );
    final hasNonLbtcNegative = negativeBalances.any(
      (b) => b.assetId != Asset.lbtc.id,
    );

    final uniqueAssets = {
      ...positiveBalances.map((b) => b.assetId),
      ...negativeBalances.map((b) => b.assetId),
    };

    final hasTokens = transaction.balances.any(
      (b) => b.assetId == Asset.usdt.id || b.assetId == Asset.depix.id,
    );

    final isPotentialSwap =
        (hasMultipleAssets && hasNonLbtcPositive && hasNonLbtcNegative) ||
        (hasTokens && hasMultipleAssets && uniqueAssets.length >= 2) ||
        (uniqueAssets.length > 2);

    if (isPotentialSwap || transaction.type == TransactionType.swap) {
      final nonLbtcPositive =
          positiveBalances.where((b) => b.assetId != Asset.lbtc.id).toList();
      final nonLbtcNegative =
          negativeBalances.where((b) => b.assetId != Asset.lbtc.id).toList();

      // Asset (to)
      if (nonLbtcPositive.isNotEmpty) {
        final receivedBalance = nonLbtcPositive.first;
        toAsset = Asset.fromId(receivedBalance.assetId);
        receivedAmount = BigInt.from(receivedBalance.value);
      } else if (positiveBalances.isNotEmpty) {
        final receivedBalance = positiveBalances.first;
        toAsset = Asset.fromId(receivedBalance.assetId);
        receivedAmount = BigInt.from(receivedBalance.value);
      }

      // Asset (from)
      if (nonLbtcNegative.isNotEmpty) {
        final sentBalance = nonLbtcNegative.first;
        fromAsset = Asset.fromId(sentBalance.assetId);
        sentAmount = BigInt.from(sentBalance.value.abs());
      } else if (negativeBalances.isNotEmpty) {
        final sentBalance = negativeBalances.first;
        fromAsset = Asset.fromId(sentBalance.assetId);
        sentAmount = BigInt.from(sentBalance.value.abs());
      }
    }

    return Transaction(
      id: transaction.txid,
      amount: transaction.amount,
      blockchain: Blockchain.liquid,
      asset: transaction.asset,
      type: transaction.type,
      status: transaction.status,
      createdAt: transaction.createdAt,
      fromAsset: fromAsset,
      toAsset: toAsset,
      sentAmount: sentAmount,
      receivedAmount: receivedAmount,
    );
  }
}

extension ToTransaction on lwk.Tx {
  TransactionType get type {
    final positiveBalances = balances.where((b) => b.value > 0).toList();
    final negativeBalances = balances.where((b) => b.value < 0).toList();

    if (kind == "redeposit") {
      return TransactionType.redeposit;
    }

    if (positiveBalances.isNotEmpty && negativeBalances.isNotEmpty) {
      final uniquePositiveAssets =
          positiveBalances.map((b) => b.assetId).toSet();
      final uniqueNegativeAssets =
          negativeBalances.map((b) => b.assetId).toSet();

      final totalUniqueAssets =
          {...uniquePositiveAssets, ...uniqueNegativeAssets}.length;
      final hasMultipleAssets = totalUniqueAssets > 1;

      if (hasMultipleAssets) {
        final hasNonLbtcPositive = positiveBalances.any(
          (b) => b.assetId != Asset.lbtc.id,
        );
        final hasNonLbtcNegative = negativeBalances.any(
          (b) => b.assetId != Asset.lbtc.id,
        );

        if (hasNonLbtcPositive || hasNonLbtcNegative) {
          final hasUsdt = balances.any((b) => b.assetId == Asset.usdt.id);
          final hasDepix = balances.any((b) => b.assetId == Asset.depix.id);
          final hasLbtc = balances.any((b) => b.assetId == Asset.lbtc.id);

          if ((hasUsdt || hasDepix) && hasLbtc && totalUniqueAssets >= 2) {
            return TransactionType.swap;
          }

          if (hasNonLbtcPositive && hasNonLbtcNegative) {
            return TransactionType.swap;
          }
        }

        final onlyNonLbtcPositive = hasNonLbtcPositive && !hasNonLbtcNegative;
        if (onlyNonLbtcPositive) {
          return TransactionType.receive;
        }

        final onlyNonLbtcNegative = hasNonLbtcNegative && !hasNonLbtcPositive;
        if (onlyNonLbtcNegative) {
          return TransactionType.send;
        }
      }
    }

    if (positiveBalances.isNotEmpty && negativeBalances.isEmpty) {
      return TransactionType.receive;
    }

    if (negativeBalances.isNotEmpty && positiveBalances.isEmpty) {
      return TransactionType.send;
    }

    if (kind == "incoming") {
      return TransactionType.receive;
    }

    if (kind == "outgoing") {
      return TransactionType.send;
    }

    return TransactionType.unknown;
  }

  Asset get asset {
    if (balances.length == 1) {
      return Asset.fromId(balances.first.assetId);
    }

    final nonLbtcBalances =
        balances.where((bal) => bal.assetId != Asset.lbtc.id).toList();
    if (nonLbtcBalances.isNotEmpty) {
      final maxBalance = nonLbtcBalances.reduce(
        (a, b) => a.value.abs() > b.value.abs() ? a : b,
      );
      return Asset.fromId(maxBalance.assetId);
    }
    return Asset.fromId(balances.first.assetId);
  }

  BigInt get amount {
    if (balances.length == 1) {
      return BigInt.from(balances.first.value.abs());
    }

    final nonLbtcBalances =
        balances.where((bal) => bal.assetId != Asset.lbtc.id).toList();
    if (nonLbtcBalances.isNotEmpty) {
      final maxBalance = nonLbtcBalances.reduce(
        (a, b) => a.value.abs() > b.value.abs() ? a : b,
      );
      return BigInt.from(maxBalance.value.abs());
    }

    return BigInt.from(balances.first.value.abs());
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

    return DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000);
  }
}
