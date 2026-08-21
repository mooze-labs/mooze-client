import 'package:flutter/foundation.dart';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as breez;
import 'package:mooze_mobile/domain/entities/liquid_utxo.dart' as v2;
import 'package:mooze_mobile/domain/entities/refund.dart' as v2;
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/bitcoin.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/breez.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/liquid.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';
import 'package:mooze_mobile/shared/concurrency/liquid_spend_coordinator.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class _TransactionProcessingData {
  final List<Transaction> breezTxs;
  final List<Transaction> liquidTxs;
  final List<Transaction> btcTxs;

  _TransactionProcessingData({
    required this.breezTxs,
    required this.liquidTxs,
    required this.btcTxs,
  });
}

List<Transaction> _processTransactionsInIsolate(
  _TransactionProcessingData data,
) {
  debugPrint(
    '[_processTransactionsInIsolate] Input - Breez: ${data.breezTxs.length}, Liquid: ${data.liquidTxs.length}, BTC: ${data.btcTxs.length}',
  );

  // Print all Breez transactions before filtering
  if (data.breezTxs.isNotEmpty) {
    debugPrint('==================== BREEZ TRANSACTIONS ====================');
    for (var i = 0; i < data.breezTxs.length; i++) {
      final tx = data.breezTxs[i];
      debugPrint(
        '[$i] Breez: ${tx.id} | ${tx.type} | ${tx.asset.ticker} | ${tx.status} | ${tx.amount} sats | ${tx.createdAt}',
      );
      if (tx.type == TransactionType.submarine) {
        debugPrint(
          '    Submarine: ${tx.fromAsset?.ticker} → ${tx.toAsset?.ticker} | sendTx: ${tx.sendTxId} | receiveTx: ${tx.receiveTxId}',
        );
      }
    }
  }

  // // Print all Liquid transactions before filtering
  // if (data.liquidTxs.isNotEmpty) {
  //   debugPrint('==================== LIQUID TRANSACTIONS ====================');
  //   for (var i = 0; i < data.liquidTxs.length; i++) {
  //     final tx = data.liquidTxs[i];
  //     debugPrint(
  //       '[$i] Liquid: ${tx.id} | ${tx.type} | ${tx.asset.ticker} | ${tx.status} | ${tx.amount} sats | ${tx.createdAt}',
  //     );
  //   }
  // }

  // // Print all Bitcoin transactions before filtering
  // if (data.btcTxs.isNotEmpty) {
  //   debugPrint('==================== BITCOIN TRANSACTIONS ====================');
  //   for (var i = 0; i < data.btcTxs.length; i++) {
  //     final tx = data.btcTxs[i];
  //     debugPrint(
  //       '[$i] Bitcoin: ${tx.id} | ${tx.type} | ${tx.asset.ticker} | ${tx.status} | ${tx.amount} sats | ${tx.createdAt}',
  //     );
  //   }
  // }

  final breezIds = data.breezTxs.map((tx) => tx.id).toSet();
  final filteredLiquidTxs =
      data.liquidTxs.where((tx) => !breezIds.contains(tx.id)).toList();

  debugPrint(
    '[_processTransactionsInIsolate] Filtered ${data.liquidTxs.length - filteredLiquidTxs.length} duplicate Liquid transactions',
  );

  // Collect all transaction IDs that are part of submarine swaps
  final submarineSwapTxIds = <String>{};
  for (final tx in data.breezTxs) {
    if (tx.type == TransactionType.submarine) {
      if (tx.sendTxId != null) {
        submarineSwapTxIds.add(tx.sendTxId!);
        debugPrint(
          '[_processTransactionsInIsolate] Submarine swap ${tx.id} has sendTxId: ${tx.sendTxId}',
        );
      }
      if (tx.receiveTxId != null) {
        submarineSwapTxIds.add(tx.receiveTxId!);
        debugPrint(
          '[_processTransactionsInIsolate] Submarine swap ${tx.id} has receiveTxId: ${tx.receiveTxId}',
        );
      }
    }
  }

  debugPrint(
    '[_processTransactionsInIsolate] Found ${submarineSwapTxIds.length} transaction IDs that are part of submarine swaps: $submarineSwapTxIds',
  );

  // Filter out Bitcoin transactions that are already part of submarine swaps
  final filteredBtcTxs =
      data.btcTxs.where((tx) => !submarineSwapTxIds.contains(tx.id)).toList();

  final removedBtcTxs = data.btcTxs.length - filteredBtcTxs.length;
  if (removedBtcTxs > 0) {
    debugPrint(
      '[_processTransactionsInIsolate] Filtered $removedBtcTxs Bitcoin transactions that are part of submarine swaps',
    );
    for (final tx in data.btcTxs) {
      if (submarineSwapTxIds.contains(tx.id)) {
        debugPrint('  - Removed Bitcoin TX: ${tx.id} (${tx.amount} sats)');
      }
    }
  } else {
    debugPrint(
      '[_processTransactionsInIsolate] No Bitcoin transactions were filtered',
    );
  }

  final allTransactions = [
    ...data.breezTxs,
    ...filteredLiquidTxs,
    ...filteredBtcTxs,
  ];

  debugPrint(
    '[_processTransactionsInIsolate] Total before sort: ${allTransactions.length}',
  );

  allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final result = _identifyInternalSwapsStatic(allTransactions);

  debugPrint(
    '[_processTransactionsInIsolate] Final result after swap identification: ${result.length}',
  );

  return result;
}

List<Transaction> _identifyInternalSwapsStatic(List<Transaction> transactions) {
  final result = <Transaction>[];
  final processedIds = <String>{};
  int swapsFound = 0;

  debugPrint(
    '[_identifyInternalSwapsStatic] Processing ${transactions.length} transactions...',
  );

  for (int i = 0; i < transactions.length; i++) {
    if (processedIds.contains(transactions[i].id)) {
      continue;
    }

    final tx1 = transactions[i];

    // Skip submarine swaps as they are already properly formatted from Breez SDK
    if (tx1.type == TransactionType.submarine) {
      result.add(tx1);
      continue;
    }

    if (tx1.type != TransactionType.send) {
      result.add(tx1);
      continue;
    }

    bool foundSwapPair = false;

    for (int j = 0; j < transactions.length; j++) {
      if (j == i || processedIds.contains(transactions[j].id)) {
        continue;
      }

      final tx2 = transactions[j];

      if (tx2.type != TransactionType.receive) {
        continue;
      }

      final isBtcToLbtcSwap =
          tx1.asset == Asset.btc &&
          tx2.asset == Asset.lbtc &&
          tx1.blockchain == Blockchain.bitcoin &&
          tx2.blockchain == Blockchain.liquid;

      final isLbtcToBtcSwap =
          tx1.asset == Asset.lbtc &&
          tx2.asset == Asset.btc &&
          tx1.blockchain == Blockchain.liquid &&
          tx2.blockchain == Blockchain.bitcoin;

      if (!isBtcToLbtcSwap && !isLbtcToBtcSwap) {
        continue;
      }

      final minAmount = BigInt.from(25000);
      final sentAmount = tx1.amount;
      final receivedAmount = tx2.amount;

      final minExpectedReceived =
          (sentAmount * BigInt.from(90)) ~/ BigInt.from(100);
      final maxExpectedReceived =
          (sentAmount * BigInt.from(101)) ~/ BigInt.from(100);

      final hasValidAmount =
          sentAmount >= minAmount &&
          receivedAmount >= minExpectedReceived &&
          receivedAmount <= maxExpectedReceived;

      // Check if transactions occurred within a reasonable time window for a swap
      // Submarine swaps typically complete within 1-2 hours
      final timeDifference = tx1.createdAt.difference(tx2.createdAt).abs();
      final maxSwapDuration = Duration(hours: 12);
      final isWithinTimeWindow = timeDifference <= maxSwapDuration;

      if (hasValidAmount && isWithinTimeWindow) {
        swapsFound++;
        debugPrint(
          '[_identifyInternalSwapsStatic] Found swap #$swapsFound: ${tx1.id} + ${tx2.id} (time diff: ${timeDifference.inMinutes}min)',
        );

        final swapDate =
            tx1.createdAt.isBefore(tx2.createdAt)
                ? tx1.createdAt
                : tx2.createdAt;

        final swapTx = Transaction(
          id: '${tx1.id}_${tx2.id}_swap',
          amount: tx2.amount,
          blockchain: tx2.blockchain,
          asset: tx2.asset,
          type: TransactionType.swap,
          status:
              tx1.status == TransactionStatus.confirmed &&
                      tx2.status == TransactionStatus.confirmed
                  ? TransactionStatus.confirmed
                  : TransactionStatus.pending,
          createdAt: swapDate,
          fromAsset: tx1.asset,
          toAsset: tx2.asset,
          sentAmount: tx1.amount,
          receivedAmount: tx2.amount,
          sendTxId: tx1.id,
          receiveTxId: tx2.id,
          sendBlockchain: tx1.blockchain,
          receiveBlockchain: tx2.blockchain,
        );

        result.add(swapTx);
        processedIds.add(tx1.id);
        processedIds.add(tx2.id);
        foundSwapPair = true;
        break;
      }
    }

    if (!foundSwapPair) {
      result.add(tx1);
    }
  }

  debugPrint(
    '[_identifyInternalSwapsStatic] Found $swapsFound swap pairs, reduced ${transactions.length} → ${result.length} transactions',
  );

  return result;
}

class WalletRepositoryImpl extends WalletRepository {
  final BreezWallet? _breezWallet;
  final BitcoinWallet? _bitcoinWallet;
  final LiquidWallet? _liquidWallet;
  final SwapAuditRepository? _swapAudit;

  WalletRepositoryImpl(
    BreezWallet? breezWallet,
    BitcoinWallet? bitcoinWallet,
    LiquidWallet? liquidWallet, {
    SwapAuditRepository? swapAudit,
  }) : _breezWallet = breezWallet,
       _bitcoinWallet = bitcoinWallet,
       _liquidWallet = liquidWallet,
       _swapAudit = swapAudit;

  // Helper to get Breez wallet or return error
  TaskEither<WalletError, T> _withBreez<T>(
    TaskEither<WalletError, T> Function(BreezWallet) fn,
  ) {
    if (_breezWallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Breez wallet not available'),
      );
    }
    return fn(_breezWallet!);
  }

  // Helper to get Bitcoin wallet or return error
  TaskEither<WalletError, T> _withBitcoin<T>(
    TaskEither<WalletError, T> Function(BitcoinWallet) fn,
  ) {
    if (_bitcoinWallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Bitcoin wallet not available'),
      );
    }
    return fn(_bitcoinWallet!);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _withBitcoin((btc) => btc.createBitcoinInvoice(amount, description));
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLiquidBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _withBreez(
      (breez) => breez.createLiquidBitcoinInvoice(amount, description),
    );
  }

  @override
  TaskEither<WalletError, PaymentRequest> createStablecoinInvoice(
    Asset asset,
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _withBreez(
      (breez) => breez.createStablecoinInvoice(asset, amount, description),
    );
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildStablecoinPaymentTransaction(
    String destination,
    Asset asset,
    double amount,
  ) {
    return _withBreez(
      (breez) =>
          breez.buildStablecoinPaymentTransaction(destination, asset, amount),
    );
  }

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(
    String destination,
    BigInt amount, [
    int? feeRateSatPerVByte,
    Asset? asset,
  ]) {
    if (asset == Asset.lbtc || destination.startsWith('lq1')) {
      return _withBreez(
        (breez) => breez.buildOnchainBitcoinPaymentTransaction(
          destination,
          amount,
          feeRateSatPerVByte,
        ),
      );
    }

    return _withBitcoin(
      (btc) => btc.buildOnchainBitcoinPaymentTransaction(
        destination,
        amount,
        feeRateSatPerVByte,
      ),
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount) {
    return _withBreez(
      (breez) =>
          breez.buildLiquidBitcoinPaymentTransaction(destination, amount),
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLiquidBitcoinTransaction(String destination) {
    return _withBreez(
      (breez) => breez.buildDrainLiquidBitcoinTransaction(destination),
    );
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildDrainStablecoinTransaction(String destination, Asset asset) {
    return _withBreez(
      (breez) => breez.buildDrainStablecoinTransaction(destination, asset),
    );
  }

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildDrainOnchainBitcoinTransaction(
    String destination, {
    Asset? asset,
    int? feeRateSatPerVbyte,
  }) {
    if (asset == Asset.lbtc || destination.startsWith('lq1')) {
      return _withBreez(
        (breez) => breez.buildDrainOnchainBitcoinTransaction(
          destination,
          feeRateSatPerVbyte: feeRateSatPerVbyte,
        ),
      );
    }

    return _withBitcoin(
      (btc) => btc.buildDrainOnchainBitcoinTransaction(
        destination,
        feeRateSatPerVbyte: feeRateSatPerVbyte,
      ),
    );
  }

  @override
  TaskEither<WalletError, Transaction> sendL2BitcoinPayment(
    PreparedLayer2BitcoinTransaction psbt,
  ) {
    return _withLiquidSpendLock(
      'breez:sendL2Bitcoin',
      () => _withBreez((breez) => breez.sendL2BitcoinPayment(psbt)),
    );
  }

  @override
  TaskEither<WalletError, Transaction> sendStablecoinPayment(
    PreparedStablecoinTransaction psbt,
  ) {
    return _withLiquidSpendLock(
      'breez:sendStablecoin',
      () => _withBreez((breez) => breez.sendStablecoinPayment(psbt)),
    );
  }

  TaskEither<WalletError, Transaction> _withLiquidSpendLock(
    String label,
    TaskEither<WalletError, Transaction> Function() body,
  ) {
    return TaskEither(() async {
      try {
        return await LiquidSpendCoordinator.instance.protect(
          label,
          () => body().run(),
        );
      } on LiquidSpendLockTimeout catch (e) {
        return left(
          WalletError(WalletErrorType.transactionFailed, e.toString()),
        );
      }
    });
  }

  @override
  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  ) {
    if (psbt.destination.startsWith('lq1')) {
      return _withBreez((breez) => breez.sendOnchainBitcoinPayment(psbt));
    }
    return _withBitcoin((btc) => btc.sendOnchainBitcoinPayment(psbt));
  }

  @override
  TaskEither<WalletError, Balance> getBalance() {
    return TaskEither.tryCatch(
      () async {
        final Balance balance = {};

        // Try to get Breez balance (L-BTC and Liquid assets)
        if (_breezWallet != null) {
          final breezResult = await _breezWallet!.getBalance().run();
          breezResult.fold(
            (err) {
              if (kDebugMode) {
                debugPrint('[getBalance] Breez balance failed: $err');
              }
            },
            (breezBal) {
              balance.addAll(breezBal);
              if (kDebugMode) {
                debugPrint(
                  '[getBalance] Breez balance loaded: ${breezBal.keys.map((a) => a.ticker).join(", ")}',
                );
              }
            },
          );
        } else {
          if (kDebugMode) {
            debugPrint('[getBalance] Breez wallet not available');
          }
        }

        // Try LWK for Liquid assets (independent from Breez)
        // LWK manages on-chain Liquid assets, while Breez manages Lightning/Liquid channels
        // Both sources can have balances simultaneously
        if (_liquidWallet != null) {
          try {
            final liquidResult = await _liquidWallet!.getBalance().run();
            liquidResult.fold(
              (err) {
                if (kDebugMode) {
                  debugPrint('[getBalance] Liquid (LWK) balance failed: $err');
                }
              },
              (liquidBal) {
                // Add L-BTC and other Liquid assets from LWK
                // Use putIfAbsent to avoid overwriting Breez balances
                for (final entry in liquidBal.entries) {
                  balance.putIfAbsent(entry.key, () => entry.value);
                }
                if (kDebugMode) {
                  debugPrint(
                    '[getBalance] Liquid (LWK) balance loaded: ${liquidBal.keys.map((a) => a.ticker).join(", ")}',
                  );
                }
              },
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[getBalance] Liquid (LWK) balance exception: $e');
            }
          }
        }

        // Get BDK balance for on-chain BTC
        if (_bitcoinWallet != null) {
          _bitcoinWallet!.balance.fold(
            (err) {
              if (kDebugMode) {
                debugPrint('[getBalance] BDK balance failed: $err');
              }
            },
            (btcBal) {
              balance[Asset.btc] = btcBal;
              if (kDebugMode) {
                debugPrint('[getBalance] BDK balance loaded: $btcBal sats');
              }
            },
          );
        } else {
          if (kDebugMode) {
            debugPrint('[getBalance] BDK wallet not available');
          }
        }

        if (kDebugMode) {
          debugPrint('[getBalance] Final balance:');
          for (final entry in balance.entries) {
            debugPrint('  ${entry.key.ticker}: ${entry.value} sats');
          }
        }

        return balance;
      },
      (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('[getBalance] Error: $error');
          debugPrint('[getBalance] StackTrace: $stackTrace');
        }
        return WalletError(
          WalletErrorType.sdkError,
          'Failed to get balance: $error',
        );
      },
    );
  }

  @override
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
        final List<Future<Either<WalletError, List<Transaction>>>> futures = [];

        // Add Breez transactions if available
        if (_breezWallet != null) {
          futures.add(
            _breezWallet!
                .getTransactions(
                  type: type,
                  status: status,
                  asset: asset,
                  blockchain: blockchain,
                  startDate: startDate,
                  endDate: endDate,
                )
                .run(),
          );
        }

        // Add Liquid transactions if available
        if (_liquidWallet != null) {
          futures.add(
            _liquidWallet!
                .getTransactions(
                  type: type,
                  status: status,
                  blockchain: blockchain,
                  asset: asset,
                  startDate: startDate,
                  endDate: endDate,
                )
                .run(),
          );
        }

        // Add Bitcoin transactions if available
        if (_bitcoinWallet != null) {
          futures.add(
            _bitcoinWallet!
                .getTransactions(
                  type: type,
                  status: status,
                  blockchain: blockchain,
                  asset: asset,
                  startDate: startDate,
                  endDate: endDate,
                )
                .run(),
          );
        }

        if (futures.isEmpty) {
          return <Transaction>[];
        }

        final results = await Future.wait(futures);

        // Parse results based on available wallets
        int resultIndex = 0;

        List<Transaction> breezTxs = <Transaction>[];
        List<Transaction> liquidTxs = <Transaction>[];
        List<Transaction> btcTxs = <Transaction>[];

        if (_breezWallet != null && resultIndex < results.length) {
          breezTxs = results[resultIndex].fold(
            (error) {
              debugPrint('Error fetching breez transactions: $error');
              return <Transaction>[];
            },
            (txs) {
              debugPrint(
                '[WalletRepository] 🔵 Breez: ${txs.length} transactions',
              );
              return txs;
            },
          );
          resultIndex++;
        }

        if (_liquidWallet != null && resultIndex < results.length) {
          liquidTxs = results[resultIndex].fold(
            (error) {
              debugPrint('Error fetching liquid transactions: $error');
              return <Transaction>[];
            },
            (txs) {
              debugPrint(
                '[WalletRepository] 🔷 Liquid: ${txs.length} transactions',
              );
              return txs;
            },
          );
          resultIndex++;
        }

        if (_bitcoinWallet != null && resultIndex < results.length) {
          btcTxs = results[resultIndex].fold(
            (error) {
              debugPrint('Error fetching bitcoin transactions: $error');
              return <Transaction>[];
            },
            (txs) {
              debugPrint(
                '[WalletRepository] 🟠 Bitcoin: ${txs.length} transactions',
              );
              return txs;
            },
          );
        }

        debugPrint(
          '[WalletRepository] 📊 Total BEFORE processing: ${breezTxs.length + liquidTxs.length + btcTxs.length}',
        );

        final processedTransactions = await compute(
          _processTransactionsInIsolate,
          _TransactionProcessingData(
            breezTxs: breezTxs,
            liquidTxs: liquidTxs,
            btcTxs: btcTxs,
          ),
        );

        debugPrint(
          '[WalletRepository] ✅ Total AFTER processing: ${processedTransactions.length}',
        );

        // Persist any internal-Liquid swaps detected by the matcher into
        // the immutable Swaps table. Idempotent — recordCompleted skips
        // if a row for (provider=internal_liquid, txId=sendLeg) already
        // exists. Errors are swallowed inside the audit repo (fail-open).
        await _persistInternalSwaps(processedTransactions);

        return processedTransactions;
      },
      (error, stackTrace) =>
          WalletError(WalletErrorType.sdkError, error.toString()),
    );
  }

  /// Persist swaps detected by [_identifyInternalSwapsStatic] into the
  /// immutable Swaps table. The matcher emits a synthesized Transaction
  /// with `type=swap` and the original send/receive leg ids in
  /// `sendTxId`/`receiveTxId`; we record one swap row per pair.
  ///
  /// Idempotent: [SwapAuditRepository.recordCompleted] does an existence
  /// check on (provider='internal_liquid', txId=<sendTxId>) so re-running
  /// the matcher across multiple syncs does not duplicate.
  Future<void> _persistInternalSwaps(List<Transaction> processed) async {
    final audit = _swapAudit;
    if (audit == null) return;

    for (final tx in processed) {
      if (tx.type != TransactionType.swap) continue;
      // Only record if we have both legs identified — submarine swaps from
      // Breez go through their own (currently deferred) recording path.
      if (tx.sendTxId == null || tx.receiveTxId == null) continue;
      // Skip if the matcher built this from Breez output (sendBlockchain
      // crosses chains). Internal Liquid swaps stay on Liquid for both legs.
      if (tx.sendBlockchain == Blockchain.bitcoin ||
          tx.receiveBlockchain == Blockchain.bitcoin) {
        continue;
      }

      final fromAsset = tx.fromAsset?.id ?? 'unknown';
      final toAsset = tx.toAsset?.id ?? 'unknown';
      final sendAmount = tx.sentAmount ?? tx.amount;
      final receiveAmount = tx.receivedAmount ?? tx.amount;

      await audit.recordCompleted(
        provider: 'internal_liquid',
        direction: 'asset_swap',
        sendAsset: fromAsset,
        receiveAsset: toAsset,
        sendAmount: sendAmount,
        receiveAmount: receiveAmount,
        txId: tx.sendTxId,
        metadata: {
          'sendTxId': tx.sendTxId,
          'receiveTxId': tx.receiveTxId,
          'status': tx.status.name,
        },
      );
    }
  }

  @override
  TaskEither<WalletError, String> getBitcoinReceiveAddress() {
    if (_bitcoinWallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Bitcoin wallet not available'),
      );
    }
    // Routing through createBitcoinInvoice keeps a single source of truth
    // for the unused-address verification logic that lives in BitcoinWallet.
    return _bitcoinWallet
        .createBitcoinInvoice(const None(), const None())
        .flatMap((req) => TaskEither.right(req.address));
  }

  @override
  TaskEither<WalletError, String> getLiquidReceiveAddress() {
    if (_liquidWallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Liquid wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async {
        final address =
            await _liquidWallet!.datasource.wallet.addressLastUnused();
        return address.confidential;
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.sdkError,
        'Erro ao obter endereço Liquid: $error',
      ),
    );
  }

  // ─────────────────────────────────────────── chain metadata

  @override
  TaskEither<WalletError, int> getCurrentBitcoinBlockHeight() {
    final wallet = _bitcoinWallet;
    if (wallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Bitcoin wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async => await wallet.datasource.blockchain.getHeight(),
      (error, stackTrace) => WalletError(
        WalletErrorType.networkError,
        'Erro ao obter altura do bloco Bitcoin: $error',
      ),
    );
  }

  // ─────────────────────────────────────────── refund surface
  //
  // Phase 2.3.3-prep-A2/A3: refund flows route through here instead of
  // reading `breezClientProvider` directly. Translates Breez SDK types
  // to V2 domain types at the boundary so feature/UI layers stay free
  // of `flutter_breez_liquid` imports.

  @override
  TaskEither<WalletError, List<v2.RefundableSwap>> listRefundableSwaps() {
    final w = _breezWallet;
    if (w == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Breez wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async {
        final list = await w.sdkClient.listRefundables();
        return list
            .map(
              (r) => v2.RefundableSwap(
                swapAddress: r.swapAddress,
                amountSat: r.amountSat.toInt(),
                lastRefundTxId: r.lastRefundTxId,
                timestamp:
                    r.timestamp == 0
                        ? null
                        : DateTime.fromMillisecondsSinceEpoch(
                          r.timestamp * 1000,
                        ),
              ),
            )
            .toList();
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.networkError,
        'Erro ao listar reembolsos disponíveis: $error',
      ),
    );
  }

  @override
  TaskEither<WalletError, v2.MempoolFees> getRecommendedFees() {
    final w = _breezWallet;
    if (w == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Breez wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async {
        final f = await w.sdkClient.recommendedFees();
        return v2.MempoolFees(
          minimumFee: f.minimumFee.toInt(),
          economyFee: f.economyFee.toInt(),
          hourFee: f.hourFee.toInt(),
          halfHourFee: f.halfHourFee.toInt(),
          fastestFee: f.fastestFee.toInt(),
        );
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.networkError,
        'Erro ao obter taxas recomendadas: $error',
      ),
    );
  }

  @override
  TaskEither<WalletError, v2.PrepareRefundOutcome> prepareRefund(
    v2.PrepareRefundParams params,
  ) {
    final w = _breezWallet;
    if (w == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Breez wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async {
        final resp = await w.sdkClient.prepareRefund(
          req: breez.PrepareRefundRequest(
            swapAddress: params.swapAddress,
            refundAddress: params.refundAddress,
            feeRateSatPerVbyte: params.feeRateSatPerVbyte,
          ),
        );
        return v2.PrepareRefundOutcome(
          txVsize: resp.txVsize,
          feesSat: resp.txFeeSat.toInt(),
          refundTxId: resp.lastRefundTxId,
        );
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        'Erro ao preparar reembolso: $error',
      ),
    );
  }

  @override
  TaskEither<WalletError, v2.RefundOutcome> executeRefund(
    v2.ExecuteRefundParams params,
  ) {
    final w = _breezWallet;
    if (w == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Breez wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async {
        final resp = await w.sdkClient.refund(
          req: breez.RefundRequest(
            swapAddress: params.swapAddress,
            refundAddress: params.refundAddress,
            feeRateSatPerVbyte: params.feeRateSatPerVbyte,
          ),
        );
        return v2.RefundOutcome(refundTxId: resp.refundTxId);
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        'Erro ao executar reembolso: $error',
      ),
    );
  }

  // ─────────────────────────────────────────── swap surface (LWK-backed)
  //
  // Phase 2.3.3-prep-Tier3: swap flows route through here so they no
  // longer reach `liquidDataSourceProvider` directly. Delegates to the
  // existing legacy LWK datasource via `_liquidWallet.datasource.wallet`.
  // Translates LWK UTXO types to V2 domain `LiquidUtxo` at the boundary.

  @override
  TaskEither<WalletError, List<v2.LiquidUtxo>> getLiquidUtxos() {
    final w = _liquidWallet;
    if (w == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Liquid wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async {
        final utxos = await w.datasource.wallet.utxos();
        return utxos
            .map(
              (u) => v2.LiquidUtxo(
                txid: u.outpoint.txid,
                vout: u.outpoint.vout,
                assetId: u.unblinded.asset,
                assetBlindingFactor: u.unblinded.assetBf,
                valueSat: u.unblinded.value,
                valueBlindingFactor: u.unblinded.valueBf,
              ),
            )
            .toList();
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.sdkError,
        'Erro ao listar UTXOs Liquid: $error',
      ),
    );
  }

  @override
  TaskEither<WalletError, String> signSwapPset({
    required String pset,
    required String mnemonic,
  }) {
    final w = _liquidWallet;
    if (w == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Liquid wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async {
        final signed = await w.datasource.wallet.signedPsetWithExtraDetails(
          network: w.datasource.network,
          pset: pset,
          mnemonic: mnemonic,
        );
        return signed;
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        'Erro ao assinar PSET de swap: $error',
      ),
    );
  }

  @override
  TaskEither<WalletError, String> getLiquidSwapAddress() {
    final w = _liquidWallet;
    if (w == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Liquid wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async {
        final address = await w.datasource.wallet.addressLastUnused();
        return address.confidential;
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.sdkError,
        'Erro ao obter endereço Liquid para swap: $error',
      ),
    );
  }
}
