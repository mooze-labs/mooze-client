import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart'
    show PreparedOnchainBitcoinTransaction;
import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/infra/bdk/wallet.dart';

class BitcoinWallet {
  final BdkDataSource _datasource;

  BitcoinWallet(BdkDataSource datasource) : _datasource = datasource;

  Either<WalletError, BigInt> get balance {
    return Either.tryCatch(
      () => _datasource.wallet.getBalance().spendable,
      (err, _) => WalletError(
        WalletErrorType.connectionError,
        "Falha ao acessar saldo.",
      ),
    );
  }

  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    final address =
        _datasource.wallet
            .getAddress(addressIndex: bdk.AddressIndex.increase())
            .address
            .toString();
    final paymentRequest = PaymentRequest(
      address: address,
      blockchain: Blockchain.bitcoin,
      asset: Asset.btc,
      fees: BigInt.zero,
      amount: amount.fold(() => null, (i) => i),
      description: description.toNullable(),
    );

    return TaskEither.right(paymentRequest);
  }

  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(String destination, BigInt amount) {
    if (amount < _datasource.wallet.getBalance().spendable) {
      return TaskEither.left(WalletError(WalletErrorType.insufficientFunds));
    }

    return _buildPsbt(destination, amount).flatMap(
      (r) => TaskEither.right(
        PreparedOnchainBitcoinTransaction(
          destination: destination,
          amount: amount,
          networkFees: r.$1.feeAmount() ?? BigInt.zero,
          drain: false,
        ),
      ),
    );
  }

  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildDrainOnchainBitcoinTransaction(String destination) {
    return _parseAddress(destination).flatMap(
      (scriptPubKey) => TaskEither.tryCatch(
        () async {
          final (tx, details) = await bdk.TxBuilder()
              .drainWallet()
              .drainTo(scriptPubKey)
              .enableRbf()
              .finish(_datasource.wallet);

          return PreparedOnchainBitcoinTransaction(
            destination: destination,
            amount: details.sent,
            networkFees: tx.feeAmount() ?? BigInt.zero,
            drain: true,
          );
        },
        (err, _) =>
            WalletError(WalletErrorType.transactionFailed, err.toString()),
      ),
    );
  }

  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  ) {
    final partialTransaction =
        (psbt.drain)
            ? _buildDrainPsbt(psbt.destination)
            : _buildPsbt(psbt.destination, psbt.amount);

    return partialTransaction.flatMap(
      (psbtTuple) =>
          TaskEither.fromEither(_signTransaction(psbtTuple.$1)).flatMap(
            (signedPsbt) => TaskEither.tryCatch(() async {
              final txid = await _datasource.blockchain.broadcast(
                transaction: signedPsbt.extractTx(),
              );

              return Transaction(
                id: txid,
                amount: psbt.amount,
                blockchain: Blockchain.bitcoin,
                asset: Asset.btc,
                type: TransactionType.send,
                status: TransactionStatus.pending,
                createdAt: DateTime.now(),
              );
            }, (err, _) => WalletError(WalletErrorType.connectionError)),
          ),
    );
  }

  Either<WalletError, List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final walletTxs = Either.tryCatch(
      () {
        final transactions = _datasource.wallet.listTransactions(includeRaw: false);
        print("Transactions: ${transactions.length}");
        return transactions;
      },
      (err, _) {
        if (kDebugMode) {
          debugPrint(err.toString());
        }
        return WalletError(
          WalletErrorType.sdkError,
          "[BDK] Falha ao ler histórico de transações",
        );
      },
    );
    return walletTxs.flatMap(
      (txs) => Either.right(
        txs
            .map(
              (tx) => Transaction(
                id: tx.txid,
                amount: (tx.received > BigInt.zero) ? tx.received : tx.sent,
                blockchain: Blockchain.bitcoin,
                asset: Asset.btc,
                type:
                    (tx.received > BigInt.zero)
                        ? TransactionType.receive
                        : TransactionType.send,
                status:
                    (tx.confirmationTime == null)
                        ? TransactionStatus.pending
                        : TransactionStatus.confirmed,

                /// TODO: Remove datetime.now() for non-confirmed transactions
                createdAt:
                    (tx.confirmationTime == null)
                        ? DateTime.now()
                        : DateTime.fromMillisecondsSinceEpoch(
                          tx.confirmationTime!.timestamp.toInt(),
                        ),
              ),
            )
            .toList(),
      ),
    );
  }

  TaskEither<
    WalletError,
    (bdk.PartiallySignedTransaction, bdk.TransactionDetails)
  >
  _buildPsbt(String address, BigInt amount) {
    return _parseAddress(address).flatMap(
      (scriptBuf) => TaskEither.tryCatch(
        () async {
          final (psbt, details) = await bdk.TxBuilder()
              .addRecipient(scriptBuf, amount)
              .enableRbf()
              .finish(_datasource.wallet);

          return (psbt, details);
        },
        (err, _) =>
            WalletError(WalletErrorType.transactionFailed, err.toString()),
      ),
    );
  }

  TaskEither<
    WalletError,
    (bdk.PartiallySignedTransaction, bdk.TransactionDetails)
  >
  _buildDrainPsbt(String address) {
    return _parseAddress(address).flatMap(
      (scriptBuf) => TaskEither.tryCatch(
        () async => await bdk.TxBuilder()
            .drainWallet()
            .drainTo(scriptBuf)
            .finish(_datasource.wallet),
        (err, _) =>
            WalletError(WalletErrorType.transactionFailed, err.toString()),
      ),
    );
  }

  TaskEither<WalletError, bdk.ScriptBuf> _parseAddress(String address) {
    return TaskEither.tryCatch(
      () async => await bdk.Address.fromString(
        s: address,
        network: _datasource.wallet.network(),
      ).then((a) => a.scriptPubkey()),
      (err, _) => WalletError(WalletErrorType.invalidAddress, err.toString()),
    );
  }

  Either<WalletError, bdk.PartiallySignedTransaction> _signTransaction(
    bdk.PartiallySignedTransaction psbt,
  ) {
    final psbtClone = psbt;
    final sign = _datasource.wallet.sign(psbt: psbtClone);

    if (sign) {
      return Either.right(psbtClone);
    }

    return Either.left(
      WalletError(
        WalletErrorType.transactionFailed,
        "Failed to sign transaction.",
      ),
    );
  }
}
