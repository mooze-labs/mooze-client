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
  final breezIds = data.breezTxs.map((tx) => tx.id).toSet();
  final filteredLiquidTxs =
      data.liquidTxs.where((tx) => !breezIds.contains(tx.id)).toList();
  final allTransactions = [
    ...data.breezTxs,
    ...filteredLiquidTxs,
    ...data.btcTxs,
  ];

  allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return _identifyInternalSwapsStatic(allTransactions);
}

List<Transaction> _identifyInternalSwapsStatic(List<Transaction> transactions) {
  final result = <Transaction>[];
  final processedIds = <String>{};

  for (int i = 0; i < transactions.length; i++) {
    if (processedIds.contains(transactions[i].id)) {
      continue;
    }

    final tx1 = transactions[i];

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

      if (hasValidAmount) {
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
  return result;
}

class WalletRepositoryImpl extends WalletRepository {
  final BreezWallet _breezWallet;
  final BitcoinWallet _bitcoinWallet;
  final LiquidWallet _liquidWallet;

  WalletRepositoryImpl(
    BreezWallet breezWallet,
    BitcoinWallet bitcoinWallet,
    LiquidWallet liquidWallet,
  ) : _breezWallet = breezWallet,
      _bitcoinWallet = bitcoinWallet,
      _liquidWallet = liquidWallet;

  @override
  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _bitcoinWallet.createBitcoinInvoice(amount, description);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLightningInvoice(
    BigInt amount,
    Option<String> description,
  ) {
    return _breezWallet.createLightningInvoice(amount, description);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLiquidBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _breezWallet.createLiquidBitcoinInvoice(amount, description);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createStablecoinInvoice(
    Asset asset,
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _breezWallet.createStablecoinInvoice(asset, amount, description);
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildStablecoinPaymentTransaction(
    String destination,
    Asset asset,
    double amount,
  ) {
    return _breezWallet.buildStablecoinPaymentTransaction(
      destination,
      asset,
      amount,
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
      return _breezWallet.buildOnchainBitcoinPaymentTransaction(
        destination,
        amount,
        feeRateSatPerVByte,
      );
    }

    return _bitcoinWallet.buildOnchainBitcoinPaymentTransaction(
      destination,
      amount,
      feeRateSatPerVByte,
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLightningPaymentTransaction(String destination, BigInt amount) {
    return _breezWallet.buildLightningPaymentTransaction(destination, amount);
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount) {
    return _breezWallet.buildLiquidBitcoinPaymentTransaction(
      destination,
      amount,
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLightningTransaction(String destination) {
    return _breezWallet.buildDrainLightningTransaction(destination);
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLiquidBitcoinTransaction(String destination) {
    return _breezWallet.buildDrainLiquidBitcoinTransaction(destination);
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildDrainStablecoinTransaction(String destination, Asset asset) {
    return _breezWallet.buildDrainStablecoinTransaction(destination, asset);
  }

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildDrainOnchainBitcoinTransaction(
    String destination, {
    Asset? asset,
    int? feeRateSatPerVbyte,
  }) {
    if (asset == Asset.lbtc || destination.startsWith('lq1')) {
      return _breezWallet.buildDrainOnchainBitcoinTransaction(
        destination,
        feeRateSatPerVbyte: feeRateSatPerVbyte,
      );
    }

    return _bitcoinWallet.buildDrainOnchainBitcoinTransaction(
      destination,
      feeRateSatPerVbyte: feeRateSatPerVbyte,
    );
  }

  @override
  TaskEither<WalletError, Transaction> sendL2BitcoinPayment(
    PreparedLayer2BitcoinTransaction psbt,
  ) {
    return _breezWallet.sendL2BitcoinPayment(psbt);
  }

  @override
  TaskEither<WalletError, Transaction> sendStablecoinPayment(
    PreparedStablecoinTransaction psbt,
  ) {
    return _breezWallet.sendStablecoinPayment(psbt);
  }

  @override
  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  ) {
    if (psbt.destination.startsWith('lq1')) {
      return _breezWallet.sendOnchainBitcoinPayment(psbt);
    }
    return _bitcoinWallet.sendOnchainBitcoinPayment(psbt);
  }

  @override
  TaskEither<WalletError, Balance> getBalance() {
    final breezBalance = _breezWallet.getBalance();
    final bitcoinBalance = _bitcoinWallet.balance;
    final unifiedBalance = breezBalance.flatMap((breezBal) {
      return TaskEither.fromEither(
        bitcoinBalance.flatMap((btcBal) {
          breezBal[Asset.btc] = btcBal;
          if (kDebugMode) {
            for (final balance in breezBal.entries) {
              debugPrint("${balance.key} - ${balance.value}");
            }
          }
          return Either<WalletError, Balance>.right(breezBal);
        }),
      );
    });

    return unifiedBalance;
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
    final breezTransactions = _breezWallet.getTransactions(
      type: type,
      status: status,
      asset: asset,
      blockchain: blockchain,
      startDate: startDate,
      endDate: endDate,
    );

    final liquidTransactions = _liquidWallet.getTransactions(
      type: type,
      status: status,
      blockchain: blockchain,
      asset: asset,
      startDate: startDate,
      endDate: endDate,
    );

    final bitcoinTransactions = _bitcoinWallet.getTransactions(
      type: type,
      status: status,
      blockchain: blockchain,
      asset: asset,
      startDate: startDate,
      endDate: endDate,
    );

    return TaskEither.tryCatch(
      () async {
        final results = await Future.wait([
          breezTransactions.run(),
          liquidTransactions.run(),
          bitcoinTransactions.run(),
        ]);

        final List<Transaction> breezTxs = results[0].fold((error) {
          debugPrint('Error fetching breez transactions: $error');
          return <Transaction>[];
        }, (txs) => txs);

        final List<Transaction> liquidTxs = results[1].fold((error) {
          debugPrint('Error fetching liquid transactions: $error');
          return <Transaction>[];
        }, (txs) => txs);

        final List<Transaction> btcTxs = results[2].fold((error) {
          debugPrint('Error fetching bitcoin transactions: $error');
          return <Transaction>[];
        }, (txs) => txs);

        final processedTransactions = await compute(
          _processTransactionsInIsolate,
          _TransactionProcessingData(
            breezTxs: breezTxs,
            liquidTxs: liquidTxs,
            btcTxs: btcTxs,
          ),
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
    return _breezWallet.fetchLightningLimits();
  }

  @override
  TaskEither<WalletError, PaymentLimits> fetchOnchainLimits() {
    return _breezWallet.fetchOnchainPaymentLimits().map((limits) => limits.$2);
  }

  @override
  TaskEither<WalletError, PaymentLimits> fetchOnchainReceiveLimits() {
    return _breezWallet.fetchOnchainPaymentLimits().map((limits) => limits.$1);
  }

  @override
  TaskEither<WalletError, BigInt> preparePegOut({
    required BigInt receiverAmountSat,
    int? feeRateSatPerVbyte,
    bool drain = false,
  }) {
    return _breezWallet.preparePegOut(
      receiverAmountSat: receiverAmountSat,
      feeRateSatPerVbyte: feeRateSatPerVbyte,
      drain: drain,
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
    return _breezWallet.executePegOut(
      btcAddress: btcAddress,
      receiverAmountSat: receiverAmountSat,
      totalFeesSat: totalFeesSat,
      feeRateSatPerVbyte: feeRateSatPerVbyte,
      drain: drain,
    );
  }

  @override
  TaskEither<WalletError, ({String bitcoinAddress, BigInt feesSat})>
  preparePegIn({required BigInt payerAmountSat}) {
    return _breezWallet.preparePegIn(payerAmountSat: payerAmountSat);
  }

  @override
  TaskEither<WalletError, ({String bitcoinAddress, BigInt feesSat})>
  preparePegInWithFees({
    required BigInt payerAmountSat,
    int? feeRateSatPerVByte,
  }) {
    final effectiveFeeRate = feeRateSatPerVByte ?? 3;

    return TaskEither.tryCatch(
      () async {
        final dummyAddress = _bitcoinWallet.datasource.wallet.getAddress(
          addressIndex: bdk.AddressIndex.peek(index: 0),
        );
        return dummyAddress.address.toString();
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        'Erro ao obter endereço: $error',
      ),
    ).flatMap((dummyAddressStr) {
      final balance = _bitcoinWallet.datasource.wallet.getBalance();
      final estimateAmount =
          payerAmountSat < balance.spendable ~/ BigInt.from(2)
              ? payerAmountSat
              : balance.spendable ~/ BigInt.from(2);

      return _bitcoinWallet
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

            return _breezWallet
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
    final effectiveFeeRate = feeRateSatPerVByte ?? 3;

    if (kDebugMode) {
      print(
        '[WalletRepoImpl] preparePegInWithFullFees - amount: $payerAmountSat, feeRate: $effectiveFeeRate sat/vB',
      );
    }

    return TaskEither.tryCatch(
      () async {
        final dummyAddress = _bitcoinWallet.datasource.wallet.getAddress(
          addressIndex: bdk.AddressIndex.peek(index: 0),
        );
        return dummyAddress.address.toString();
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        'Erro ao obter endereço: $error',
      ),
    ).flatMap((dummyAddressStr) {
      final balance = _bitcoinWallet.datasource.wallet.getBalance();
      final estimateAmount =
          payerAmountSat < balance.spendable ~/ BigInt.from(2)
              ? payerAmountSat
              : balance.spendable ~/ BigInt.from(2);

      return _bitcoinWallet
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
                  'Saldo insuficiente ($bdkFees sats)',
                ),
              );
            }

            return _breezWallet
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
  }) {
    final effectiveFeeRate = feeRateSatPerVByte ?? 3;

    return TaskEither.tryCatch(
      () async {
        final dummyAddress = _bitcoinWallet.datasource.wallet.getAddress(
          addressIndex: bdk.AddressIndex.peek(index: 0),
        );
        return dummyAddress.address.toString();
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        'Erro ao obter endereço: $error',
      ),
    ).flatMap((dummyAddressStr) {
      final balance = _bitcoinWallet.datasource.wallet.getBalance();
      final estimateAmount =
          amount < balance.spendable ~/ BigInt.from(2)
              ? amount
              : balance.spendable ~/ BigInt.from(2);

      return _bitcoinWallet
          .buildOnchainBitcoinPaymentTransaction(
            dummyAddressStr,
            estimateAmount,
            effectiveFeeRate,
          )
          .flatMap((estimatedTx) {
            final bdkFees = estimatedTx.networkFees;

            final adjustedAmount = amount - bdkFees;

            if (adjustedAmount <= BigInt.zero) {
              return TaskEither<WalletError, Transaction>.left(
                WalletError(
                  WalletErrorType.insufficientFunds,
                  'Saldo insuficiente para cobrir as taxas de rede ($bdkFees sats)',
                ),
              );
            }

            return _breezWallet
                .preparePegIn(payerAmountSat: adjustedAmount)
                .flatMap((pegInResult) {
                  String cleanAddress = pegInResult.bitcoinAddress;
                  if (cleanAddress.startsWith('bitcoin:')) {
                    cleanAddress = cleanAddress.substring(8);
                    final queryIndex = cleanAddress.indexOf('?');
                    if (queryIndex != -1) {
                      cleanAddress = cleanAddress.substring(0, queryIndex);
                    }
                  }

                  return _bitcoinWallet
                      .buildOnchainBitcoinPaymentTransaction(
                        cleanAddress,
                        adjustedAmount,
                        effectiveFeeRate,
                      )
                      .flatMap((preparedTx) {
                        return _bitcoinWallet.sendOnchainBitcoinPayment(
                          preparedTx,
                        );
                      });
                });
          });
    });
  }

  @override
  TaskEither<WalletError, String> getBitcoinReceiveAddress() {
    return TaskEither.tryCatch(
      () async {
        final addressInfo = _bitcoinWallet.datasource.wallet.getAddress(
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
    return TaskEither.tryCatch(
      () async {
        final address =
            await _liquidWallet.datasource.wallet.addressLastUnused();
        return address.confidential;
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.sdkError,
        'Erro ao obter endereço Liquid: $error',
      ),
    );
  }
}
