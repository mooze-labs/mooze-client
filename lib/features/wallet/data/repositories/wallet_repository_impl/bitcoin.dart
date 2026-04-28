import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
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

  BdkDataSource get datasource => _datasource;

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
    return _nextUnusedReceiveAddress().flatMap((address) {
      return TaskEither.right(
        PaymentRequest(
          address: address,
          blockchain: Blockchain.bitcoin,
          asset: Asset.btc,
          fees: BigInt.zero,
          amount: amount.fold(() => null, (i) => i),
          description: description.toNullable(),
        ),
      );
    });
  }

  /// Returns the next receive address with no on-chain history.
  ///
  /// `AddressIndex.increase()` blindly advances the descriptor index without
  /// checking history; after a wallet restore (or if BDK's internal counter
  /// drifts), it can hand out an address that has already received funds.
  /// This method walks the descriptor forward from BDK's `lastUnused()`
  /// position until it finds an address whose script does not appear in any
  /// known UTXO or historical output, and only then advances the internal
  /// counter past it.
  TaskEither<WalletError, String> _nextUnusedReceiveAddress() {
    return TaskEither.tryCatch(
      () async {
        final usedScripts = _buildUsedScriptSet();

        final last = _datasource.wallet
            .getAddress(addressIndex: bdk.AddressIndex.lastUnused());
        var index = last.index;
        var addrStr = last.address.asString();
        var scriptHex = _scriptHex(last.address.scriptPubkey().bytes);

        const cap = 100;
        var walked = 0;
        while (usedScripts.contains(scriptHex) && walked < cap) {
          index++;
          walked++;
          final info = _datasource.wallet
              .getAddress(addressIndex: bdk.AddressIndex.peek(index: index));
          addrStr = info.address.asString();
          scriptHex = _scriptHex(info.address.scriptPubkey().bytes);
        }

        if (usedScripts.contains(scriptHex)) {
          throw StateError(
            'No unused receive address found within $cap-index window.',
          );
        }

        // Pin BDK's internal counter past this index so subsequent
        // .increase() calls won't return earlier addresses.
        _datasource.wallet
            .getAddress(addressIndex: bdk.AddressIndex.reset(index: index));

        return addrStr;
      },
      (err, _) =>
          WalletError(WalletErrorType.sdkError, err.toString()),
    );
  }

  Set<String> _buildUsedScriptSet() {
    final used = <String>{};
    for (final u in _datasource.wallet.listUnspent()) {
      used.add(_scriptHex(u.txout.scriptPubkey.bytes));
    }
    for (final tx in _datasource.wallet.listTransactions(includeRaw: true)) {
      final raw = tx.transaction;
      if (raw == null) continue;
      for (final out in raw.output()) {
        used.add(_scriptHex(out.scriptPubkey.bytes));
      }
    }
    return used;
  }

  String _scriptHex(List<int> bytes) {
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write((b & 0xff).toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(
    String destination,
    BigInt amount, [
    int? feeRateSatPerVByte,
  ]) {
    if (amount > _datasource.wallet.getBalance().spendable) {}

    return _buildPsbt(destination, amount, feeRateSatPerVByte).flatMap((r) {
      return TaskEither.right(
        PreparedOnchainBitcoinTransaction(
          destination: destination,
          amount: amount,
          networkFees: r.$2.fee ?? BigInt.zero,
          drain: false,
          feeRateSatPerVByte: feeRateSatPerVByte,
        ),
      );
    });
  }

  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildDrainOnchainBitcoinTransaction(
    String destination, {
    int? feeRateSatPerVbyte,
  }) {
    return _parseAddress(destination).flatMap(
      (scriptPubKey) => TaskEither.tryCatch(
        () async {
          final builder =
              bdk.TxBuilder().drainWallet().drainTo(scriptPubKey).enableRbf();

          if (feeRateSatPerVbyte != null) {
            builder.feeRate(feeRateSatPerVbyte.toDouble());
          }

          final (tx, details) = await builder.finish(_datasource.wallet);

          return PreparedOnchainBitcoinTransaction(
            destination: destination,
            amount: details.sent,
            networkFees: tx.feeAmount() ?? BigInt.zero,
            drain: true,
            feeRateSatPerVByte: feeRateSatPerVbyte,
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
            ? _buildDrainPsbt(psbt.destination, psbt.feeRateSatPerVByte)
            : _buildPsbt(
              psbt.destination,
              psbt.amount,
              psbt.feeRateSatPerVByte,
            );

    return partialTransaction.flatMap((psbtTuple) {
      return TaskEither.fromEither(_signTransaction(psbtTuple.$1)).flatMap((
        signedPsbt,
      ) {
        return TaskEither.tryCatch(
          () async {
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
          },
          (err, _) {
            return WalletError(WalletErrorType.connectionError);
          },
        );
      });
    });
  }

  TaskEither<WalletError, List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TaskEither.tryCatch(
      () async {
        await _datasource.sync();

        final rawTxs = _datasource.wallet.listTransactions(includeRaw: false);

        final transactions =
            rawTxs.map((tx) {
              final isSend = tx.sent > tx.received;
              final amount = isSend ? (tx.sent - tx.received) : tx.received;

              return Transaction(
                id: tx.txid,
                amount: amount,
                blockchain: Blockchain.bitcoin,
                asset: Asset.btc,
                type: isSend ? TransactionType.send : TransactionType.receive,
                status:
                    (tx.confirmationTime == null)
                        ? TransactionStatus.pending
                        : TransactionStatus.confirmed,

                createdAt:
                    (tx.confirmationTime == null)
                        ? DateTime.now()
                        : DateTime.fromMillisecondsSinceEpoch(
                          tx.confirmationTime!.timestamp.toInt() * 1000,
                        ),
                confirmationHeight: tx.confirmationTime?.height,
              );
            }).toList();

        return transactions;
      },
      (err, _) {
        return WalletError(
          WalletErrorType.sdkError,
          "[BDK] Falha ao ler histórico de transações: $err",
        );
      },
    );
  }

  TaskEither<
    WalletError,
    (bdk.PartiallySignedTransaction, bdk.TransactionDetails)
  >
  _buildPsbt(String address, BigInt amount, [int? feeRateSatPerVByte]) {
    return _parseAddress(address).flatMap(
      (scriptBuf) => TaskEither.tryCatch(
        () async {
          final builder =
              bdk.TxBuilder().addRecipient(scriptBuf, amount).enableRbf();

          // Custom fee
          // final testFeeRate = 0.1;
          // builder.feeRate(testFeeRate);

          if (feeRateSatPerVByte != null) {
            builder.feeRate(feeRateSatPerVByte.toDouble());
          }

          final (psbt, details) = await builder.finish(_datasource.wallet);
          return (psbt, details);
        },
        (err, _) {
          return WalletError(WalletErrorType.transactionFailed, err.toString());
        },
      ),
    );
  }

  TaskEither<
    WalletError,
    (bdk.PartiallySignedTransaction, bdk.TransactionDetails)
  >
  _buildDrainPsbt(String address, [int? feeRateSatPerVByte]) {
    return _parseAddress(address).flatMap(
      (scriptBuf) => TaskEither.tryCatch(
        () async {
          final builder =
              bdk.TxBuilder().drainWallet().drainTo(scriptBuf).enableRbf();

          if (feeRateSatPerVByte != null) {
            builder.feeRate(feeRateSatPerVByte.toDouble());
          }

          return await builder.finish(_datasource.wallet);
        },
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
