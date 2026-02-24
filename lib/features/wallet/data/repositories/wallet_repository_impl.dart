import 'package:flutter/foundation.dart';

import 'package:fpdart/fpdart.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/bitcoin.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/breez.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/liquid.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/payment_limits.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';
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

  WalletRepositoryImpl(
    BreezWallet? breezWallet,
    BitcoinWallet? bitcoinWallet,
    LiquidWallet? liquidWallet,
  ) : _breezWallet = breezWallet,
      _bitcoinWallet = bitcoinWallet,
      _liquidWallet = liquidWallet;

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

  // Helper to get Liquid wallet or return error
  TaskEither<WalletError, T> _withLiquid<T>(
    TaskEither<WalletError, T> Function(LiquidWallet) fn,
  ) {
    if (_liquidWallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Liquid wallet not available'),
      );
    }
    return fn(_liquidWallet!);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _withBitcoin((btc) => btc.createBitcoinInvoice(amount, description));
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLightningInvoice(
    BigInt amount,
    Option<String> description,
  ) {
    return _withBreez(
      (breez) => breez.createLightningInvoice(amount, description),
    );
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
  buildLightningPaymentTransaction(String destination, BigInt amount) {
    return _withBreez(
      (breez) => breez.buildLightningPaymentTransaction(destination, amount),
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
  buildDrainLightningTransaction(String destination) {
    return _withBreez(
      (breez) => breez.buildDrainLightningTransaction(destination),
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
    return _withBreez((breez) => breez.sendL2BitcoinPayment(psbt));
  }

  @override
  TaskEither<WalletError, Transaction> sendStablecoinPayment(
    PreparedStablecoinTransaction psbt,
  ) {
    return _withBreez((breez) => breez.sendStablecoinPayment(psbt));
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

        return processedTransactions;
      },
      (error, stackTrace) =>
          WalletError(WalletErrorType.sdkError, error.toString()),
    );
  }

  @override
  TaskEither<WalletError, LightningPaymentLimitsResponse>
  fetchLightningLimits() {
    return _withBreez((breez) => breez.fetchLightningLimits());
  }

  @override
  TaskEither<WalletError, PaymentLimits> fetchOnchainLimits() {
    return _withBreez(
      (breez) => breez.fetchOnchainPaymentLimits().map((limits) => limits.$2),
    );
  }

  @override
  TaskEither<WalletError, PaymentLimits> fetchOnchainReceiveLimits() {
    return _withBreez(
      (breez) => breez.fetchOnchainPaymentLimits().map((limits) => limits.$1),
    );
  }

  @override
  TaskEither<WalletError, BigInt> preparePegOut({
    required BigInt receiverAmountSat,
    int? feeRateSatPerVbyte,
    bool drain = false,
  }) {
    return _withBreez(
      (breez) => breez.preparePegOut(
        receiverAmountSat: receiverAmountSat,
        feeRateSatPerVbyte: feeRateSatPerVbyte,
        drain: drain,
      ),
    );
  }

  @override
  TaskEither<WalletError, Transaction> executePegOut({
    required String btcAddress,
    required BigInt receiverAmountSat,
    required BigInt totalFeesSat,
    int? feeRateSatPerVbyte,
    bool drain = false,
  }) {
    return _withBreez(
      (breez) => breez.executePegOut(
        btcAddress: btcAddress,
        receiverAmountSat: receiverAmountSat,
        totalFeesSat: totalFeesSat,
        feeRateSatPerVbyte: feeRateSatPerVbyte,
        drain: drain,
      ),
    );
  }

  @override
  TaskEither<WalletError, ({String bitcoinAddress, BigInt feesSat})>
  preparePegIn({required BigInt payerAmountSat}) {
    return _withBreez(
      (breez) => breez.preparePegIn(payerAmountSat: payerAmountSat),
    );
  }

  @override
  TaskEither<WalletError, ({String bitcoinAddress, BigInt feesSat})>
  preparePegInWithFees({
    required BigInt payerAmountSat,
    int? feeRateSatPerVByte,
  }) {
    if (_bitcoinWallet == null || _breezWallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Wallet not available'),
      );
    }

    final effectiveFeeRate = feeRateSatPerVByte ?? 3;

    return TaskEither.tryCatch(
      () async {
        final dummyAddress = _bitcoinWallet!.datasource.wallet.getAddress(
          addressIndex: bdk.AddressIndex.peek(index: 0),
        );
        return dummyAddress.address.toString();
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        'Erro ao obter endereço: $error',
      ),
    ).flatMap((dummyAddressStr) {
      final balance = _bitcoinWallet!.datasource.wallet.getBalance();
      final estimateAmount =
          payerAmountSat < balance.spendable ~/ BigInt.from(2)
              ? payerAmountSat
              : balance.spendable ~/ BigInt.from(2);

      return _bitcoinWallet!
          .buildOnchainBitcoinPaymentTransaction(
            dummyAddressStr,
            estimateAmount,
            effectiveFeeRate,
          )
          .flatMap((estimatedTx) {
            final bdkFees = estimatedTx.networkFees;

            final adjustedAmount = payerAmountSat - bdkFees;

            if (adjustedAmount <= BigInt.zero) {
              return TaskEither<
                WalletError,
                ({String bitcoinAddress, BigInt feesSat})
              >.left(
                WalletError(
                  WalletErrorType.insufficientFunds,
                  'Saldo insuficiente para cobrir as taxas de rede ($bdkFees sats)',
                ),
              );
            }

            return _breezWallet!
                .preparePegIn(payerAmountSat: adjustedAmount)
                .map((pegInResult) {
                  return (
                    bitcoinAddress: pegInResult.bitcoinAddress,
                    feesSat: bdkFees,
                  );
                });
          });
    });
  }

  @override
  TaskEither<WalletError, ({BigInt breezFeesSat, BigInt bdkFeesSat})>
  preparePegInWithFullFees({
    required BigInt payerAmountSat,
    int? feeRateSatPerVByte,
  }) {
    if (_bitcoinWallet == null || _breezWallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Wallet not available'),
      );
    }

    final effectiveFeeRate = feeRateSatPerVByte ?? 3;

    if (kDebugMode) {
      print(
        '[WalletRepoImpl] preparePegInWithFullFees - amount: $payerAmountSat, feeRate: $effectiveFeeRate sat/vB',
      );
    }

    return TaskEither.tryCatch(
      () async {
        final dummyAddress = _bitcoinWallet!.datasource.wallet.getAddress(
          addressIndex: bdk.AddressIndex.peek(index: 0),
        );
        return dummyAddress.address.toString();
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        'Erro ao obter endereço: $error',
      ),
    ).flatMap((dummyAddressStr) {
      final balance = _bitcoinWallet!.datasource.wallet.getBalance();
      final estimateAmount =
          payerAmountSat < balance.spendable ~/ BigInt.from(2)
              ? payerAmountSat
              : balance.spendable ~/ BigInt.from(2);

      return _bitcoinWallet!
          .buildOnchainBitcoinPaymentTransaction(
            dummyAddressStr,
            estimateAmount,
            effectiveFeeRate,
          )
          .flatMap((estimatedTx) {
            final bdkFees = estimatedTx.networkFees;

            final adjustedAmount = payerAmountSat - bdkFees;


            if (adjustedAmount <= BigInt.zero) {
              return TaskEither<
                WalletError,
                ({BigInt breezFeesSat, BigInt bdkFeesSat})
              >.left(
                WalletError(
                  WalletErrorType.insufficientFunds,
                  'Saldo insuficiente para cobrir as taxas de rede ($bdkFees sats)',
                ),
              );
            }

            return _breezWallet!
                .preparePegIn(payerAmountSat: adjustedAmount)
                .map((pegInResult) {
                  return (
                    breezFeesSat: pegInResult.feesSat,
                    bdkFeesSat: bdkFees,
                  );
                });
          });
    });
  }

  @override
  TaskEither<WalletError, Transaction> executePegIn({
    required BigInt amount,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    if (_bitcoinWallet == null || _breezWallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Wallet not available'),
      );
    }

    final effectiveFeeRate = feeRateSatPerVByte ?? 3;

    if (drain) {
      return _executeDrainPegIn(effectiveFeeRate);
    }

    return _executeNormalPegIn(amount, effectiveFeeRate);
  }

  TaskEither<WalletError, Transaction> _executeNormalPegIn(
    BigInt amount,
    int effectiveFeeRate,
  ) {
    if (kDebugMode) {
      print(
        '[WalletRepoImpl] ExecutePegIn (normal) - amount total: $amount sats, feeRate: $effectiveFeeRate sat/vB',
      );
    }

    return TaskEither.tryCatch(
      () async {
        final dummyAddress = _bitcoinWallet!.datasource.wallet.getAddress(
          addressIndex: bdk.AddressIndex.peek(index: 0),
        );
        return dummyAddress.address.toString();
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        'Erro ao obter endereço dummy: $error',
      ),
    ).flatMap((dummyAddressStr) {
      final balance = _bitcoinWallet!.datasource.wallet.getBalance().spendable;
      final estimateAmount =
          amount < balance ~/ BigInt.from(2)
              ? amount
              : balance ~/ BigInt.from(2);

      return _bitcoinWallet!
          .buildOnchainBitcoinPaymentTransaction(
            dummyAddressStr,
            estimateAmount,
            effectiveFeeRate,
          )
          .flatMap((estimatedTx) {
            final bdkFee = estimatedTx.networkFees;
            final payerAmountSat = amount - bdkFee;


            if (payerAmountSat <= BigInt.zero) {
              return TaskEither<WalletError, Transaction>.left(
                WalletError(
                  WalletErrorType.insufficientFunds,
                  'Saldo insuficiente para cobrir as taxas de rede '
                  '($bdkFee sats)',
                ),
              );
            }

            return _breezWallet!
                .preparePegIn(payerAmountSat: payerAmountSat)
                .flatMap((pegInResult) {
                  final cleanAddress = _cleanBitcoinAddress(
                    pegInResult.bitcoinAddress,
                  );

                  return _bitcoinWallet!
                      .buildOnchainBitcoinPaymentTransaction(
                        cleanAddress,
                        payerAmountSat,
                        effectiveFeeRate,
                      )
                      .flatMap((preparedTx) {
                        return _bitcoinWallet!.sendOnchainBitcoinPayment(
                          preparedTx,
                        );
                      });
                });
          });
    });
  }

  TaskEither<WalletError, Transaction> _executeDrainPegIn(
    int effectiveFeeRate,
  ) {
    final balance = _bitcoinWallet!.datasource.wallet.getBalance().spendable;

    if (balance <= BigInt.zero) {
      return TaskEither.left(
        WalletError(WalletErrorType.insufficientFunds, 'Saldo insuficiente'),
      );
    }

    return _breezWallet!.preparePegIn(payerAmountSat: balance).flatMap((
      provisionalSwap,
    ) {
      final provisionalAddress = _cleanBitcoinAddress(
        provisionalSwap.bitcoinAddress,
      );

      return _bitcoinWallet!
          .buildDrainOnchainBitcoinTransaction(
            provisionalAddress,
            feeRateSatPerVbyte: effectiveFeeRate,
          )
          .flatMap((drainEstimate) {
            final networkFee = drainEstimate.networkFees;
            final exactOutput = balance - networkFee;

            if (exactOutput <= BigInt.zero) {
              return TaskEither<WalletError, Transaction>.left(
                WalletError(
                  WalletErrorType.insufficientFunds,
                  'Saldo insuficiente para cobrir as taxas de rede '
                  '($networkFee sats)',
                ),
              );
            }

            return _breezWallet!.preparePegIn(payerAmountSat: exactOutput).flatMap((
              definitivePegIn,
            ) {
              final swapAddress = _cleanBitcoinAddress(
                definitivePegIn.bitcoinAddress,
              );

              return _bitcoinWallet!
                  .buildDrainOnchainBitcoinTransaction(
                    swapAddress,
                    feeRateSatPerVbyte: effectiveFeeRate,
                  )
                  .flatMap((drainTx) {
                    return _bitcoinWallet!.sendOnchainBitcoinPayment(drainTx);
                  });
            });
          });
    });
  }

  String _cleanBitcoinAddress(String address) {
    String clean = address;
    if (clean.startsWith('bitcoin:')) {
      clean = clean.substring(8);
      final queryIndex = clean.indexOf('?');
      if (queryIndex != -1) {
        clean = clean.substring(0, queryIndex);
      }
    }
    return clean;
  }

  @override
  TaskEither<WalletError, String> getBitcoinReceiveAddress() {
    if (_bitcoinWallet == null) {
      return TaskEither.left(
        WalletError(WalletErrorType.sdkError, 'Bitcoin wallet not available'),
      );
    }
    return TaskEither.tryCatch(
      () async {
        final addressInfo = _bitcoinWallet!.datasource.wallet.getAddress(
          addressIndex: bdk.AddressIndex.increase(),
        );
        return addressInfo.address.toString();
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.sdkError,
        'Erro ao obter endereço Bitcoin: $error',
      ),
    );
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
}
