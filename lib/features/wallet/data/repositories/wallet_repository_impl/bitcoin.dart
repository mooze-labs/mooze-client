import 'dart:convert';

import 'package:bdk_dart/bdk_dart.dart' as bdk;
import 'package:drift/drift.dart' show Value;
import 'package:fpdart/fpdart.dart';
// `Transaction` collides with the domain Transaction below; we only need
// TransactionsCompanion from drift so we hide the generated row type.
import 'package:mooze_mobile/database/database.dart' hide Transaction;
import 'package:mooze_mobile/app/di/v2_providers.dart' as v2;
import 'package:mooze_mobile/domain/entities/chain.dart' as v2chain;
import 'package:mooze_mobile/domain/entities/transaction.dart' as v2tx;
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart'
    show PreparedOnchainBitcoinTransaction;
import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/infra/bdk/bdk_wallet_x.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/infra/bdk/wallet.dart';

class BitcoinWallet {
  final BdkDataSource _datasource;
  final AppDatabase? _database;
  final AppLoggerService? _logger;

  BitcoinWallet(
    BdkDataSource datasource, {
    AppDatabase? database,
    AppLoggerService? logger,
  }) : _datasource = datasource,
       _database = database,
       _logger = logger;

  BdkDataSource get datasource => _datasource;

  Either<WalletError, BigInt> get balance {
    return Either.tryCatch(
      () => BigInt.from(
        _datasource.wallet.balance().trustedSpendable.toSat(),
      ),
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
  /// Walks forward from BDK's first unused address past any address whose
  /// script already appears in the wallet history, then persists the
  /// revealed index so later calls never go backwards. See
  /// [BdkWalletX.nextFreshReceiveAddress].
  TaskEither<WalletError, String> _nextUnusedReceiveAddress() {
    return TaskEither.tryCatch(
      () async {
        final info = _datasource.wallet.nextFreshReceiveAddress();
        _datasource.persist();
        return info.address.toString();
      },
      (err, _) =>
          WalletError(WalletErrorType.sdkError, err.toString()),
    );
  }

  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(
    String destination,
    BigInt amount, [
    int? feeRateSatPerVByte,
  ]) {
    return _buildPsbt(destination, amount, feeRateSatPerVByte).flatMap((psbt) {
      return TaskEither.right(
        PreparedOnchainBitcoinTransaction(
          destination: destination,
          amount: amount,
          networkFees: BigInt.from(psbt.fee()),
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
    return _buildDrainPsbt(destination, feeRateSatPerVbyte).flatMap(
      (psbt) => TaskEither.tryCatch(
        () async {
          // Same meaning as the legacy `details.sent`: the total value of
          // the wallet inputs the drain spends.
          final values = _datasource.wallet.sentAndReceived(
            tx: psbt.extractTxUncheckedFeeRate(),
          );

          return PreparedOnchainBitcoinTransaction(
            destination: destination,
            amount: BigInt.from(values.sent.toSat()),
            networkFees: BigInt.from(psbt.fee()),
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

    return partialTransaction.flatMap((unsignedPsbt) {
      return TaskEither.fromEither(_signTransaction(unsignedPsbt)).flatMap((
        signedPsbt,
      ) {
        return TaskEither.tryCatch(
          () async {
            final feePaidSat = signedPsbt.fee();
            final txid = await _datasource.electrum.broadcast(
              signedPsbt.extractTx(),
            );

            // Best-effort persistence: a DB error MUST NOT fail the operation,
            // because the broadcast already happened and the user's funds
            // moved. The next BDK sync (BdkDataSource._processTransactions)
            // will reconcile the row idempotently if this one is lost.
            await _persistOutgoingTx(
              txid: txid,
              destination: psbt.destination,
              amountSats: psbt.amount,
              feeRateSatPerVByte: psbt.feeRateSatPerVByte,
              drain: psbt.drain,
            );

            // The legacy persistence above writes to the legacy drift DB,
            // which the V2 home tx list does NOT read from. Notify the
            // V2 BDK service so its in-memory cache picks up the new tx
            // and the orchestrator persists it into the V2 sqlite store
            // (`transactionStore`) — that's what the home actually
            // watches. Without this, the row only appears on the next
            // successful `sync()` (when BDK's electrum scan sees the
            // mempool tx), which can be up to 60 s away.
            try {
              final btcService = _datasource.ref
                  .read(v2.bitcoinWalletServiceProvider);
              btcService.registerExternalBroadcast(v2tx.Transaction(
                id: txid,
                chain: v2chain.ChainId.bitcoin,
                direction: v2tx.TransactionDirection.outgoing,
                status: v2tx.TransactionStatus.pending,
                amountSat: psbt.amount.toInt(),
                feeSat: feePaidSat,
                timestamp: DateTime.now(),
                confirmations: 0,
                address: psbt.destination,
                source: v2tx.TransactionSource.bdk,
              ));
            } catch (e, st) {
              // Failing to register into the V2 cache is non-fatal —
              // the funds already moved and the next BDK sync still
              // reconciles eventually. Log so we can spot misconfigured
              // DI in the field.
              _logger?.error(
                'BitcoinWallet',
                'registerExternalBroadcast failed (broadcast already succeeded)',
                error: e,
                stackTrace: st,
              );
            }

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

  Future<void> _persistOutgoingTx({
    required String txid,
    required String destination,
    required BigInt amountSats,
    required int? feeRateSatPerVByte,
    required bool drain,
  }) async {
    if (_database == null) return;
    try {
      await _database.upsertTransaction(
        TransactionsCompanion.insert(
          id: txid,
          assetId: 'btc',
          amount: amountSats,
          type: 'send',
          status: 'pending',
          createdAt: DateTime.now(),
          confirmations: const Value(0),
          txHash: Value(txid),
          address: Value(destination),
          metadata: Value(
            jsonEncode({
              'feeRateSatPerVByte': feeRateSatPerVByte,
              'drain': drain,
            }),
          ),
          blockchain: 'bitcoin',
        ),
      );
      _logger?.info(
        'BitcoinWallet',
        'Outgoing BTC tx persisted: txid=$txid amount=$amountSats',
      );
    } catch (e, st) {
      _logger?.error(
        'BitcoinWallet',
        'Failed to persist outgoing BTC tx $txid (broadcast already succeeded)',
        error: e,
        stackTrace: st,
      );
    }
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

        final rawTxs = _datasource.wallet.txViews();

        final transactions =
            rawTxs.map((tx) {
              final isSend = tx.sentSat > tx.receivedSat;
              final amount =
                  isSend ? (tx.sentSat - tx.receivedSat) : tx.receivedSat;

              return Transaction(
                id: tx.txid,
                amount: BigInt.from(amount),
                blockchain: Blockchain.bitcoin,
                asset: Asset.btc,
                type: isSend ? TransactionType.send : TransactionType.receive,
                status:
                    tx.isConfirmed
                        ? TransactionStatus.confirmed
                        : TransactionStatus.pending,

                createdAt: tx.confirmationTime ?? DateTime.now(),
                confirmationHeight: tx.confirmationHeight,
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

  // `TxBuilder` methods return a new builder, so each step reassigns it.
  // RBF is signaled by default in BDK 1.x.
  TaskEither<WalletError, bdk.Psbt> _buildPsbt(
    String address,
    BigInt amount, [
    int? feeRateSatPerVByte,
  ]) {
    return _parseAddress(address).flatMap(
      (script) => TaskEither.tryCatch(
        () async {
          var builder = bdk.TxBuilder().addRecipient(
            script: script,
            amount: bdk.Amount.fromSat(satoshi: amount.toInt()),
          );

          if (feeRateSatPerVByte != null) {
            builder = builder.feeRate(
              feeRate: bdk.FeeRate.fromSatPerVb(satVb: feeRateSatPerVByte),
            );
          }

          return builder.finish(wallet: _datasource.wallet);
        },
        (err, _) {
          return WalletError(WalletErrorType.transactionFailed, err.toString());
        },
      ),
    );
  }

  TaskEither<WalletError, bdk.Psbt> _buildDrainPsbt(
    String address, [
    int? feeRateSatPerVByte,
  ]) {
    return _parseAddress(address).flatMap(
      (script) => TaskEither.tryCatch(
        () async {
          var builder = bdk.TxBuilder().drainWallet().drainTo(script: script);

          if (feeRateSatPerVByte != null) {
            builder = builder.feeRate(
              feeRate: bdk.FeeRate.fromSatPerVb(satVb: feeRateSatPerVByte),
            );
          }

          return builder.finish(wallet: _datasource.wallet);
        },
        (err, _) =>
            WalletError(WalletErrorType.transactionFailed, err.toString()),
      ),
    );
  }

  TaskEither<WalletError, bdk.Script> _parseAddress(String address) {
    return TaskEither.tryCatch(
      () async => bdk.Address(
        address: address,
        network: _datasource.wallet.network(),
      ).scriptPubkey(),
      (err, _) => WalletError(WalletErrorType.invalidAddress, err.toString()),
    );
  }

  Either<WalletError, bdk.Psbt> _signTransaction(bdk.Psbt psbt) {
    final sign = _datasource.wallet.sign(psbt: psbt, signOptions: null);

    if (sign) {
      return Either.right(psbt);
    }

    return Either.left(
      WalletError(
        WalletErrorType.transactionFailed,
        "Failed to sign transaction.",
      ),
    );
  }
}
