import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart'
    hide LightningPaymentLimitsResponse;
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/data/dto/payment_request_dto.dart';
import 'package:mooze_mobile/features/wallet/data/dto/transaction_dto.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/payment_limits.dart';

import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../dto/psbt_dto.dart';

class BreezWallet {
  final BreezSdkLiquid _breez;

  BreezWallet(this._breez);

  TaskEither<WalletError, LightningPaymentLimitsResponse>
  fetchLightningLimits() {
    return TaskEither.tryCatch(
      () async {
        final breezLimits = await _breez.fetchLightningLimits();
        return LightningPaymentLimitsResponse(
          receive: PaymentLimits(
            minSat: breezLimits.receive.minSat,
            maxSat: breezLimits.receive.maxSat,
          ),
          send: PaymentLimits(
            minSat: breezLimits.send.minSat,
            maxSat: breezLimits.send.maxSat,
          ),
        );
      },
      (err, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        "Falha ao buscar limites lightning: $err",
      ),
    );
  }

  TaskEither<WalletError, (PaymentLimits, PaymentLimits)>
  fetchOnchainPaymentLimits() {
    final paymentLimits = TaskEither.tryCatch(
      () async => await _breez.fetchOnchainLimits(),
      (err, _) => WalletError(WalletErrorType.sdkError, err.toString()),
    );

    return paymentLimits.flatMap(
      (lim) => TaskEither.right((
        PaymentLimits(minSat: lim.receive.minSat, maxSat: lim.receive.maxSat),
        PaymentLimits(minSat: lim.send.minSat, maxSat: lim.send.maxSat),
      )),
    );
  }

  TaskEither<WalletError, (PaymentLimits, PaymentLimits)>
  fetchLightningPaymentLimits() {
    final paymentLimits = TaskEither.tryCatch(
      () async => await _breez.fetchLightningLimits(),
      (err, _) => WalletError(WalletErrorType.sdkError, err.toString()),
    );

    return paymentLimits.flatMap(
      (lim) => TaskEither.right((
        PaymentLimits(minSat: lim.receive.minSat, maxSat: lim.receive.maxSat),
        PaymentLimits(minSat: lim.send.minSat, maxSat: lim.send.maxSat),
      )),
    );
  }

  TaskEither<WalletError, BigInt> preparePegOut({
    required BigInt receiverAmountSat,
    int? feeRateSatPerVbyte,
    bool drain = false,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (kDebugMode) {
          print(
            '[BreezWallet] Preparando peg-out - receiverAmount: $receiverAmountSat sats, drain: $drain, feeRate: $feeRateSatPerVbyte sat/vB',
          );
        }

        final payAmount =
            drain
                ? PayAmount_Drain()
                : PayAmount_Bitcoin(receiverAmountSat: receiverAmountSat);

        final prepareReq = PreparePayOnchainRequest(
          amount: payAmount,
          feeRateSatPerVbyte: feeRateSatPerVbyte,
        );

        final prepareRes = await _breez.preparePayOnchain(req: prepareReq);

        if (kDebugMode) {
          print(
            '[BreezWallet] Peg-out preparado - Total de taxas: ${prepareRes.totalFeesSat} sats',
          );
          print(
            '[BreezWallet] Detalhes - Claim fee: ${prepareRes.claimFeesSat} sats, Receiver amount: ${prepareRes.receiverAmountSat} sats',
          );
        }

        return prepareRes.totalFeesSat;
      },
      (err, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        "Falha ao preparar peg-out: $err",
      ),
    );
  }

  TaskEither<WalletError, Transaction> executePegOut({
    required String btcAddress,
    required BigInt receiverAmountSat,
    required BigInt totalFeesSat,
    int? feeRateSatPerVbyte,
    bool drain = false,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (kDebugMode) {
          print(
            '[BreezWallet] Executando peg-out - address: $btcAddress, amount: $receiverAmountSat sats, drain: $drain, fees: $totalFeesSat sats',
          );
        }

        final payAmount =
            drain
                ? PayAmount_Drain()
                : PayAmount_Bitcoin(receiverAmountSat: receiverAmountSat);

        final prepareReq = PreparePayOnchainRequest(
          amount: payAmount,
          feeRateSatPerVbyte: feeRateSatPerVbyte,
        );

        final prepareRes = await _breez.preparePayOnchain(req: prepareReq);

        // Executar o peg-out
        final payReq = PayOnchainRequest(
          address: btcAddress,
          prepareResponse: prepareRes,
        );

        final result = await _breez.payOnchain(req: payReq);

        if (kDebugMode) {
          print('[BreezWallet] Peg-out enviado com sucesso!');
        }

        return BreezTransactionDto.fromSdk(payment: result.payment).toDomain();
      },
      (err, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        "Falha ao executar peg-out: $err",
      ),
    );
  }

  TaskEither<WalletError, ({String bitcoinAddress, BigInt feesSat})>
  preparePegIn({required BigInt payerAmountSat}) {
    return TaskEither.tryCatch(
      () async {
        if (kDebugMode) {
          print(
            '[BreezWallet] Preparando peg-in - payerAmount: $payerAmountSat sats',
          );
        }

        final prepareReq = PrepareReceiveRequest(
          paymentMethod: PaymentMethod.bitcoinAddress,
          amount: ReceiveAmount_Bitcoin(payerAmountSat: payerAmountSat),
        );

        final prepareRes = await _breez.prepareReceivePayment(req: prepareReq);

        if (kDebugMode) {
          print(
            '[BreezWallet] Peg-in preparado - Taxas: ${prepareRes.feesSat} sats',
          );
        }

        final receiveRes = await _breez.receivePayment(
          req: ReceivePaymentRequest(prepareResponse: prepareRes),
        );

        final bitcoinAddress = receiveRes.destination;

        if (kDebugMode) {
          print('[BreezWallet] Endereço BTC gerado: $bitcoinAddress');
        }

        return (bitcoinAddress: bitcoinAddress, feesSat: prepareRes.feesSat);
      },
      (err, stackTrace) => WalletError(
        WalletErrorType.transactionFailed,
        "Falha ao preparar peg-in: $err",
      ),
    );
  }

  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _createOnchainBitcoinPaymentRequest(_breez, amount, description);
  }

  TaskEither<WalletError, PaymentRequest> createLightningInvoice(
    BigInt amount,
    Option<String> description,
  ) {
    return _createLightningPaymentRequest(_breez, amount, description);
  }

  TaskEither<WalletError, PaymentRequest> createLiquidBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _createLiquidBitcoinPaymentRequest(_breez, amount, description);
  }

  TaskEither<WalletError, PaymentRequest> createStablecoinInvoice(
    Asset asset,
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _createAssetPaymentRequest(_breez, asset.id, amount, description);
  }

  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildStablecoinPaymentTransaction(
    String destination,
    Asset asset,
    double amount,
  ) {
    final normalizedDestination = _normalizeLiquidAddress(destination);
    return prepareAssetSendTransaction(
      _breez,
      normalizedDestination,
      asset,
      amount,
    ).flatMap((response) {
      return TaskEither.right(
        BreezPreparedStablecoinTransactionDto(
          destination: destination,
          amount: amount,
          fees: response.feesSat ?? BigInt.zero,
          asset: asset.id,
        ).toDomain(),
      );
    });
  }

  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(
    String destination,
    BigInt amount, [
    int? feeRateSatPerVByte,
  ]) {
    return prepareOnchainSendTransaction(
      _breez,
      destination,
      amount,
      feeRateSatPerVByte,
    ).flatMap((response) {
      final preparedTx =
          BreezPreparedOnchainTransactionDto(
            destination: destination,
            fees: response.prepareResponse.totalFeesSat,
            amount: amount,
            claimFeesSat: response.prepareResponse.claimFeesSat,
          ).toDomain();

      return TaskEither.right(preparedTx);
    });
  }

  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLightningPaymentTransaction(String destination, BigInt amount) {
    return prepareLightningTransaction(_breez, destination, amount).flatMap((
      response,
    ) {
      // Handle both PrepareLnUrlPayResponse and PrepareSendResponse
      final BigInt fees;
      if (response is PrepareLnUrlPayResponse) {
        fees = response.feesSat;
      } else if (response is PrepareSendResponse) {
        fees = response.feesSat ?? BigInt.zero;
      } else {
        fees = BigInt.zero;
      }

      return TaskEither.right(
        BreezPreparedLayer2TransactionDto(
          destination: destination,
          blockchain: Blockchain.lightning,
          fees: fees,
          amount: amount,
        ).toDomain(),
      );
    });
  }

  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount) {
    final normalizedDestination = _normalizeLiquidAddress(destination);
    return prepareLayer2BitcoinSendTransaction(
      _breez,
      normalizedDestination,
      amount,
    ).flatMap((response) {
      final preparedTx =
          BreezPreparedLayer2TransactionDto(
            destination: destination,
            blockchain: Blockchain.liquid,
            fees: response.feesSat ?? BigInt.zero,
            amount: amount,
          ).toDomain();

      return TaskEither.right(preparedTx);
    });
  }

  TaskEither<WalletError, Transaction> sendStablecoinPayment(
    PreparedStablecoinTransaction psbt,
  ) {
    final normalizedDestination = _normalizeLiquidAddress(psbt.destination);
    return prepareAssetSendTransaction(
      _breez,
      normalizedDestination,
      psbt.asset,
      psbt.amount,
    ).flatMap((preparedTransaction) {
      return sendLayer2Transaction(_breez, preparedTransaction).flatMap((
        response,
      ) {
        return TaskEither.right(
          BreezTransactionDto.fromSdk(payment: response.payment).toDomain(),
        );
      });
    });
  }

  TaskEither<WalletError, Transaction> sendL2BitcoinPayment(
    PreparedLayer2BitcoinTransaction psbt,
  ) {
    if (psbt.blockchain == Blockchain.lightning) {
      // Check if this is a drain transaction (amount is 0 or very small indicates drain)
      if (psbt.amount == BigInt.zero) {
        // Handle Lightning DRAIN payments using LNURL-pay with PayAmount_Drain
        return _sendDrainLightningPayment(_breez, psbt.destination).flatMap((
          response,
        ) {
          return TaskEither.right(
            BreezTransactionDto.fromSdk(
              payment: response.data.payment,
            ).toDomain(),
          );
        });
      } else {
        // Handle both LNURL-pay and regular Lightning invoices
        return _sendLightningPaymentAny(
          _breez,
          psbt.destination,
          psbt.amount,
        ).flatMap((payment) {
          return TaskEither.right(
            BreezTransactionDto.fromSdk(payment: payment).toDomain(),
          );
        });
      }
    } else {
      // Handle Liquid payments
      final normalizedDestination = _normalizeLiquidAddress(psbt.destination);
      // Check if this is a drain transaction using the drain flag
      if (psbt.drain) {
        return _prepareDrainLayer2Response(
          _breez,
          normalizedDestination,
          Blockchain.liquid,
        ).flatMap((preparedTransaction) {
          return sendLayer2Transaction(_breez, preparedTransaction).flatMap((
            response,
          ) {
            return TaskEither.right(
              BreezTransactionDto.fromSdk(payment: response.payment).toDomain(),
            );
          });
        });
      } else {
        return prepareLayer2BitcoinSendTransaction(
          _breez,
          normalizedDestination,
          psbt.amount,
        ).flatMap((preparedTransaction) {
          return sendLayer2Transaction(_breez, preparedTransaction).flatMap((
            response,
          ) {
            return TaskEither.right(
              BreezTransactionDto.fromSdk(payment: response.payment).toDomain(),
            );
          });
        });
      }
    }
  }

  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  ) {
    // Note: feeRateSatPerVbyte is already included in the prepared transaction
    // We don't need to pass it again here
    return prepareOnchainSendTransaction(
      _breez,
      psbt.destination,
      psbt.amount,
    ).flatMap((preparedTransaction) {
      return sendOnchainTransaction(_breez, preparedTransaction).flatMap((
        response,
      ) {
        return TaskEither.right(
          BreezTransactionDto.fromSdk(payment: response.payment).toDomain(),
        );
      });
    });
  }

  // DRAIN methods - send all available funds

  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildDrainOnchainBitcoinTransaction(
    String destination, {
    int? feeRateSatPerVbyte,
  }) {
    return getBalance().flatMap((balance) {
      return _prepareDrainOnchainResponse(
        _breez,
        destination,
        feeRateSatPerVbyte: feeRateSatPerVbyte,
      ).flatMap((response) {
        return TaskEither.right(
          BreezPreparedOnchainTransactionDto(
            destination: destination,
            fees: response.prepareResponse.totalFeesSat,
            amount: response.prepareResponse.receiverAmountSat,
            claimFeesSat: response.prepareResponse.claimFeesSat,
            drain: true,
          ).toDomain(),
        );
      });
    });
  }

  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLightningTransaction(String destination) {
    return getBalance().flatMap((balance) {
      return _prepareDrainLightningResponse(_breez, destination).flatMap((
        response,
      ) {
        final BigInt resolvedAmount = switch (response.amount) {
          PayAmount_Bitcoin(receiverAmountSat: final sats) => sats,
          _ =>
            (balance[Asset.lbtc] ?? BigInt.zero) -
                response.feesSat, // balance - fees = receiver amount
        };

        return TaskEither.right(
          BreezPreparedLayer2TransactionDto(
            destination: destination,
            blockchain: Blockchain.lightning,
            fees: response.feesSat,
            amount: resolvedAmount,
            drain: true,
          ).toDomain(),
        );
      });
    });
  }

  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLiquidBitcoinTransaction(String destination) {
    final normalizedDestination = _normalizeLiquidAddress(destination);
    return getBalance().flatMap((balance) {
      return _prepareDrainLayer2Response(
        _breez,
        normalizedDestination,
        Blockchain.liquid,
      ).flatMap((response) {
        final BigInt resolvedAmount;
        if (response.exchangeAmountSat != null &&
            response.exchangeAmountSat! > BigInt.zero) {
          resolvedAmount = response.exchangeAmountSat!;
        } else {
          final payAmount = response.amount;
          if (payAmount is PayAmount_Bitcoin) {
            resolvedAmount = payAmount.receiverAmountSat;
          } else {
            resolvedAmount =
                (balance[Asset.lbtc] ?? BigInt.zero) -
                (response.feesSat ?? BigInt.zero);
          }
        }

        return TaskEither.right(
          BreezPreparedLayer2TransactionDto(
            destination: destination,
            blockchain: Blockchain.liquid,
            fees: response.feesSat ?? BigInt.zero,
            amount: resolvedAmount,
            drain: true,
          ).toDomain(),
        );
      });
    });
  }

  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildDrainStablecoinTransaction(String destination, Asset asset) {
    final normalizedDestination = _normalizeLiquidAddress(destination);
    return getBalance().flatMap((balance) {
      return _prepareDrainAssetResponse(
        _breez,
        normalizedDestination,
        asset,
      ).flatMap((response) {
        double resolvedAmount = _extractAssetAmount(response.amount);
        if (resolvedAmount <= 0) {
          resolvedAmount =
              (balance[asset] ?? BigInt.zero).toDouble() / 100000000;
        }

        return TaskEither.right(
          BreezPreparedStablecoinTransactionDto(
            destination: destination,
            amount: resolvedAmount,
            fees: response.feesSat ?? BigInt.zero,
            asset: asset.id,
            drain: true,
          ).toDomain(),
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
    final paymentType = switch (type) {
      TransactionType.send => [PaymentType.send],
      TransactionType.receive => [PaymentType.receive],
      _ => null,
    };

    final states = switch (status) {
      TransactionStatus.pending => [PaymentState.pending],
      TransactionStatus.confirmed => [PaymentState.complete],
      TransactionStatus.refundable => [
        PaymentState.refundPending,
        PaymentState.refundable,
      ],
      TransactionStatus.failed => [PaymentState.failed],
      _ => null,
    };

    return TaskEither.tryCatch(
      () async {
        final payments = await _breez.listPayments(
          req: ListPaymentsRequest(
            fromTimestamp: startDate?.millisecondsSinceEpoch,
            toTimestamp: endDate?.millisecondsSinceEpoch,
            offset: 0,
            limit: 20,
            filters: paymentType,
            states: states,
          ),
        );

        return payments
            .map((p) => BreezTransactionDto.fromSdk(payment: p).toDomain())
            .where(
              (p) => p.blockchain != Blockchain.liquid,
            ) // do NOT return Liquid payments, these will be retrieved on LWk
            .toList();
      },
      (err, stackTrace) {
        return WalletError(
          WalletErrorType.networkError,
          "Falha ao ler transações: $err",
        );
      },
    );
  }

  TaskEither<WalletError, Balance> getBalance() {
    return TaskEither.tryCatch(
      () async {
        final info = await _breez.getInfo();
        final bitcoinBalance = info.walletInfo.balanceSat;
        final assetBalances = info.walletInfo.assetBalances;

        Balance balances = {};

        for (final assetBalance in assetBalances) {
          balances[Asset.fromId(assetBalance.assetId)] =
              assetBalance.balanceSat;
        }

        balances[Asset.lbtc] = bitcoinBalance;

        return balances;
      },
      (err, stackTrace) {
        return WalletError(
          WalletErrorType.networkError,
          "Falha ao ler saldo: $err",
        );
      },
    );
  }
}

String _normalizeLiquidAddress(String address) {
  // If already has a prefix, return as is
  if (address.startsWith('liquidnetwork:') ||
      address.startsWith('liquid:') ||
      address.startsWith('bitcoin:') ||
      address.startsWith('lightning:')) {
    return address;
  }

  // Check if this is a Liquid address with query parameters
  if (_isLiquidAddressWithParams(address)) {
    return 'liquidnetwork:$address';
  }

  return address;
}

/// Helper function to detect Liquid addresses with query parameters
bool _isLiquidAddressWithParams(String address) {
  // Check if it has query parameters
  if (!address.contains('?')) {
    return false;
  }

  // Extract the base address (before ?)
  final baseAddress = address.split('?').first;

  // Check if the base address starts with Liquid prefixes
  final liquidPrefixes = [
    'lq1', // Liquid bech32
    'VJL', // Liquid P2SH
    'VT', // Liquid P2SH
    'VG', // Liquid P2SH
    'H', // Liquid legacy
    'G', // Liquid legacy
    'Az', // Liquid confidential
    'AzQ', // Liquid confidential
    'ert1', // Liquid testnet
  ];

  return liquidPrefixes.any((prefix) => baseAddress.startsWith(prefix));
}

/// RECEIVE functions
TaskEither<WalletError, PaymentRequest> _createLiquidBitcoinPaymentRequest(
  BreezSdkLiquid breez,
  Option<BigInt> amount,
  Option<String> description,
) {
  return _createBitcoinPaymentRequest(
    breez,
    PaymentMethod.liquidAddress,
    amount.flatMap((a) => Option.of(ReceiveAmount_Bitcoin(payerAmountSat: a))),
    description,
  );
}

TaskEither<WalletError, PaymentRequest> _createLightningPaymentRequest(
  BreezSdkLiquid breez,
  BigInt amount,
  Option<String> description,
) {
  return _createBitcoinPaymentRequest(
    breez,
    PaymentMethod.lightning,
    Option.of(ReceiveAmount_Bitcoin(payerAmountSat: amount)),
    description,
  );
}

TaskEither<WalletError, PaymentRequest> _createOnchainBitcoinPaymentRequest(
  BreezSdkLiquid breez,
  Option<BigInt> amount,
  Option<String> description,
) {
  return _createBitcoinPaymentRequest(
    breez,
    PaymentMethod.bitcoinAddress,
    amount.flatMap((a) => Option.of(ReceiveAmount_Bitcoin(payerAmountSat: a))),
    description,
  );
}

TaskEither<WalletError, PaymentRequest> _createBitcoinPaymentRequest(
  BreezSdkLiquid breez,
  PaymentMethod paymentMethod,
  Option<ReceiveAmount_Bitcoin> amount,
  Option<String> description,
) {
  return _prepareReceiveResponse(breez, amount, paymentMethod).flatMap(
    (prepareResponse) =>
        _receivePayment(breez, prepareResponse, description).flatMap(
          (response) => TaskEither.right(
            BreezPaymentRequestDto.fromBitcoin(
              paymentResponse: response,
              paymentMethod: PaymentMethod.bitcoinAddress,
              feesSat: prepareResponse.feesSat,
              amount: amount.flatMap((f) => Option.of(f.payerAmountSat)),
              description: description,
            ).toDomain(),
          ),
        ),
  );
}

TaskEither<WalletError, PaymentRequest> _createAssetPaymentRequest(
  BreezSdkLiquid breez,
  String assetId,
  Option<BigInt> amount,
  Option<String> description,
) {
  final ReceiveAmount_Asset recvAmount = amount.fold(
    () => ReceiveAmount_Asset(assetId: assetId),
    (amount) => ReceiveAmount_Asset(
      assetId: assetId,
      payerAmount: (amount.toInt() / pow(10, 8)).toDouble(),
    ),
  );

  return _prepareReceiveResponse(
    breez,
    Option.of(recvAmount),
    PaymentMethod.liquidAddress,
  ).flatMap(
    (prepareResponse) =>
        _receivePayment(breez, prepareResponse, description).flatMap(
          (response) => TaskEither.right(
            BreezPaymentRequestDto.fromAsset(
              paymentResponse: response,
              amount: recvAmount,
              feesSat: prepareResponse.feesSat,
            ).toDomain(),
          ),
        ),
  );
}

TaskEither<WalletError, PrepareReceiveResponse> _prepareReceiveResponse(
  BreezSdkLiquid breez,
  Option<ReceiveAmount> recvAmount,
  PaymentMethod paymentMethod,
) {
  return TaskEither.tryCatch(
    () async {
      final result = await breez.prepareReceivePayment(
        req: PrepareReceiveRequest(
          paymentMethod: paymentMethod,
          amount: recvAmount.fold(() => null, (amount) => amount),
        ),
      );
      return result;
    },
    (err, stackTrace) {
      return WalletError(WalletErrorType.networkError);
    },
  );
}

TaskEither<WalletError, ReceivePaymentResponse> _receivePayment(
  BreezSdkLiquid breez,
  PrepareReceiveResponse prepareReceiveResponse,
  Option<String> description,
) {
  return TaskEither.tryCatch(
    () async {
      final result = await breez.receivePayment(
        req: ReceivePaymentRequest(
          prepareResponse: prepareReceiveResponse,
          description: description.fold(() => null, (desc) => desc),
        ),
      );
      return result;
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.transactionFailed,
        "Falha ao gerar endereço de pagamento",
      );
    },
  );
}

// PREPARE PSBT functions.
// Functions receive BreezSdkLiquid as a parameter.
// This is to keep the functions as pure as possible.

TaskEither<WalletError, PrepareSendResponse> prepareAssetSendTransaction(
  BreezSdkLiquid breez,
  String destination,
  Asset asset,
  double amount,
) {
  final PayAmount_Asset payAmount = PayAmount_Asset(
    toAsset: asset.id,
    receiverAmount: amount,
    estimateAssetFees: false,
  );
  final PrepareSendRequest prepareSendRequest = PrepareSendRequest(
    destination: destination,
    amount: payAmount,
  );

  return TaskEither.tryCatch(
    () async {
      final result = await breez.prepareSendPayment(req: prepareSendRequest);
      return result;
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.transactionFailed,
        "Falha ao construir transação: $err",
      );
    },
  );
}

TaskEither<WalletError, PrepareSendResponse>
prepareLayer2BitcoinSendTransaction(
  BreezSdkLiquid breez,
  String destination,
  BigInt amount,
) {
  final payAmount = PayAmount_Bitcoin(receiverAmountSat: amount);
  final PrepareSendRequest sendRequest = PrepareSendRequest(
    destination: destination,
    amount: payAmount,
  );

  return TaskEither.tryCatch(
    () async {
      final result = await breez.prepareSendPayment(req: sendRequest);
      return result;
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.networkError,
        "Não foi possível preparar a transação: $err",
      );
    },
  );
}

// Lightning payment preparation - supports both LNURL-pay and regular invoices
TaskEither<WalletError, dynamic> prepareLightningTransaction(
  BreezSdkLiquid breez,
  String destination,
  BigInt amount,
) {
  return TaskEither.tryCatch(
    () async {
      // Parse the destination to determine the input type
      final inputType = await breez.parse(input: destination);

      if (inputType is InputType_LnUrlPay) {
        // Handle LNURL-pay
        final payAmount = PayAmount_Bitcoin(receiverAmountSat: amount);

        final req = PrepareLnUrlPayRequest(
          data: inputType.data,
          amount: payAmount,
          bip353Address: inputType.bip353Address,
          comment: null, // Optional comment
          validateSuccessActionUrl: true,
        );

        final result = await breez.prepareLnurlPay(req: req);

        return result;
      } else if (inputType is InputType_Bolt11) {
        // Handle regular Lightning invoice
        // Use prepareLayer2BitcoinSendTransaction for regular invoices
        final payAmount = PayAmount_Bitcoin(receiverAmountSat: amount);
        final PrepareSendRequest sendRequest = PrepareSendRequest(
          destination: destination,
          amount: payAmount,
        );

        final result = await breez.prepareSendPayment(req: sendRequest);
        return result;
      } else {
        throw Exception(
          'Tipo de destino Lightning não suportado. Use LNURL-pay ou invoice Bolt11.',
        );
      }
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.transactionFailed,
        "Não foi possível preparar a transação Lightning: $err",
      );
    },
  );
}

TaskEither<WalletError, PayOnchainRequest> prepareOnchainSendTransaction(
  BreezSdkLiquid breez,
  String destination,
  BigInt amount, [
  int? feeRateSatPerVbyte,
]) {
  return _getOnchainPaymentLimits(breez).flatMap((limits) {
    if (amount < limits.send.minSat) {
      return TaskEither.left(
        WalletError(
          WalletErrorType.invalidAmount,
          "Valor insuficiente. Mínimo: ${limits.send.minSat} sats",
        ),
      );
    }
    if (amount > limits.send.maxSat) {
      return TaskEither.left(
        WalletError(
          WalletErrorType.invalidAmount,
          "Valor inválido. Máximo: ${limits.send.maxSat} sats",
        ),
      );
    }

    return _preparePayOnchainResponse(
      breez,
      amount,
      feeRateSatPerVbyte,
    ).flatMap((r) {
      return TaskEither.right(
        PayOnchainRequest(address: destination, prepareResponse: r),
      );
    });
  });
}

TaskEither<WalletError, PreparePayOnchainResponse> _preparePayOnchainResponse(
  BreezSdkLiquid breez,
  BigInt amount, [
  int? feeRateSatPerVbyte,
]) {
  return TaskEither.tryCatch(
    () async {
      final response = await breez.preparePayOnchain(
        req: PreparePayOnchainRequest(
          amount: PayAmount_Bitcoin(receiverAmountSat: amount),
          feeRateSatPerVbyte: feeRateSatPerVbyte,
        ),
      );

      return response;
    },
    (err, stackTrace) => WalletError(
      WalletErrorType.transactionFailed,
      "Falha ao gerar transação: $err",
    ),
  );
}

TaskEither<WalletError, OnchainPaymentLimitsResponse> _getOnchainPaymentLimits(
  BreezSdkLiquid breez,
) {
  return TaskEither.tryCatch(
    () async => breez.fetchOnchainLimits(),
    (err, stackTrace) => WalletError(
      WalletErrorType.networkError,
      "Falha ao buscar limites de transação",
    ),
  );
}

// SEND PSBT functions

TaskEither<WalletError, LnUrlPayResult_EndpointSuccess>
_sendDrainLightningPayment(BreezSdkLiquid breez, String destination) {
  return TaskEither.tryCatch(
    () async {
      final inputType = await breez.parse(input: destination);

      if (inputType is InputType_LnUrlPay) {
        // Use PayAmount_Drain to send all available funds
        final drainAmount = PayAmount_Drain();

        final req = PrepareLnUrlPayRequest(
          data: inputType.data,
          amount: drainAmount,
          bip353Address: inputType.bip353Address,
          comment: null, // Optional comment
          validateSuccessActionUrl: true,
        );

        final prepareResponse = await breez.prepareLnurlPay(req: req);

        final result = await breez.lnurlPay(
          req: LnUrlPayRequest(prepareResponse: prepareResponse),
        );

        if (result is LnUrlPayResult_EndpointSuccess) {
          return result;
        } else if (result is LnUrlPayResult_PayError) {
          throw Exception('LNURL Drain Payment error: ${result.data.reason}');
        } else {
          throw Exception('Unknown LnUrlPayResult type');
        }
      } else {
        throw Exception(
          'Only LNURL-Pay destinations are supported for Lightning drain transactions',
        );
      }
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.transactionFailed,
        "Lightning drain payment failed: [BREEZ] $err",
      );
    },
  );
}

TaskEither<WalletError, LnUrlPayResult_EndpointSuccess> sendLightningPayment(
  BreezSdkLiquid breez,
  String destination,
  BigInt amount,
) {
  return TaskEither.tryCatch(
    () async {
      final inputType = await breez.parse(input: destination);

      if (inputType is InputType_LnUrlPay) {
        final payAmount = PayAmount_Bitcoin(receiverAmountSat: amount);

        final req = PrepareLnUrlPayRequest(
          data: inputType.data,
          amount: payAmount,
          bip353Address: inputType.bip353Address,
          comment: null,
          validateSuccessActionUrl: true,
        );

        final prepareResponse = await breez.prepareLnurlPay(req: req);

        final result = await breez.lnurlPay(
          req: LnUrlPayRequest(prepareResponse: prepareResponse),
        );

        if (result is LnUrlPayResult_EndpointSuccess) {
          return result;
        } else if (result is LnUrlPayResult_PayError) {
          throw Exception('LNURL Payment error: ${result.data.reason}');
        } else {
          throw Exception('Unknown LnUrlPayResult type');
        }
      } else {
        throw Exception(
          'Only LNURL-Pay destinations are supported in Lightning payments',
        );
      }
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.transactionFailed,
        "Lightning payment failed: [BREEZ] $err",
      );
    },
  );
}

// Send Lightning payment - supports both LNURL-pay and regular Bolt11 invoices
TaskEither<WalletError, Payment> _sendLightningPaymentAny(
  BreezSdkLiquid breez,
  String destination,
  BigInt amount,
) {
  return TaskEither.tryCatch(
    () async {
      final inputType = await breez.parse(input: destination);

      if (inputType is InputType_LnUrlPay) {
        // Handle LNURL-pay
        final payAmount = PayAmount_Bitcoin(receiverAmountSat: amount);

        final req = PrepareLnUrlPayRequest(
          data: inputType.data,
          amount: payAmount,
          bip353Address: inputType.bip353Address,
          comment: null,
          validateSuccessActionUrl: true,
        );

        final prepareResponse = await breez.prepareLnurlPay(req: req);

        final result = await breez.lnurlPay(
          req: LnUrlPayRequest(prepareResponse: prepareResponse),
        );

        if (result is LnUrlPayResult_EndpointSuccess) {
          return result.data.payment;
        } else if (result is LnUrlPayResult_PayError) {
          throw Exception('LNURL Payment error: ${result.data.reason}');
        } else {
          throw Exception('Unknown LnUrlPayResult type');
        }
      } else if (inputType is InputType_Bolt11) {
        // Handle regular Lightning invoice (Bolt11)
        final payAmount = PayAmount_Bitcoin(receiverAmountSat: amount);
        final PrepareSendRequest sendRequest = PrepareSendRequest(
          destination: destination,
          amount: payAmount,
        );

        final prepareResponse = await breez.prepareSendPayment(
          req: sendRequest,
        );

        final sendResponse = await breez.sendPayment(
          req: SendPaymentRequest(prepareResponse: prepareResponse),
        );

        return sendResponse.payment;
      } else {
        throw Exception(
          'Tipo de destino Lightning não suportado. Use LNURL-pay ou invoice Bolt11.',
        );
      }
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.transactionFailed,
        "Lightning payment failed: [BREEZ] $err",
      );
    },
  );
}

TaskEither<WalletError, SendPaymentResponse> sendLayer2Transaction(
  BreezSdkLiquid breez,
  PrepareSendResponse psbt,
) {
  return TaskEither.tryCatch(
    () async {
      final result = await breez.sendPayment(
        req: SendPaymentRequest(prepareResponse: psbt),
      );
      return result;
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.transactionFailed,
        "Transação falhou: [BREEZ] $err",
      );
    },
  );
}

TaskEither<WalletError, SendPaymentResponse> sendOnchainTransaction(
  BreezSdkLiquid breez,
  PayOnchainRequest psbt,
) {
  return TaskEither.tryCatch(
    () async {
      final result = await breez.payOnchain(req: psbt);
      return result;
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.transactionFailed,
        "Transação falhou: [BREEZ] $err",
      );
    },
  );
}

// DRAIN helper functions - for sending all available funds

TaskEither<WalletError, PrepareLnUrlPayResponse> _prepareDrainLightningResponse(
  BreezSdkLiquid breez,
  String destination,
) {
  return TaskEither.tryCatch(
    () async {
      // Parse the destination to determine the input type
      final inputType = await breez.parse(input: destination);

      if (inputType is InputType_LnUrlPay) {
        // Use PayAmount_Drain to send all available funds
        final drainAmount = PayAmount_Drain();

        final req = PrepareLnUrlPayRequest(
          data: inputType.data,
          amount: drainAmount,
          bip353Address: inputType.bip353Address,
          comment: null, // Optional comment
          validateSuccessActionUrl: true,
        );

        final result = await breez.prepareLnurlPay(req: req);

        return result;
      } else {
        throw Exception(
          'Only LNURL-Pay destinations are supported for Lightning drain transactions',
        );
      }
    },
    (err, stackTrace) {
      return WalletError(
        WalletErrorType.transactionFailed,
        "Falha ao preparar transação de envio total Lightning: $err",
      );
    },
  );
}

TaskEither<WalletError, PayOnchainRequest> _prepareDrainOnchainResponse(
  BreezSdkLiquid breez,
  String destination, {
  int? feeRateSatPerVbyte,
}) {
  return TaskEither.tryCatch(
    () async {
      // For drain transactions, use PayAmount_Drain to send all available funds
      final prepareResponse = await breez.preparePayOnchain(
        req: PreparePayOnchainRequest(
          amount: PayAmount_Drain(),
          feeRateSatPerVbyte: feeRateSatPerVbyte,
        ),
      );

      return PayOnchainRequest(
        address: destination,
        prepareResponse: prepareResponse,
      );
    },
    (err, stackTrace) => WalletError(
      WalletErrorType.transactionFailed,
      "Falha ao preparar transação de envio total: $err",
    ),
  );
}

TaskEither<WalletError, PrepareSendResponse> _prepareDrainLayer2Response(
  BreezSdkLiquid breez,
  String destination,
  Blockchain blockchain,
) {
  return TaskEither.tryCatch(
    () async {
      final prepareSendRequest = PrepareSendRequest(
        destination: destination,
        amount: PayAmount_Drain(),
      );

      return await breez.prepareSendPayment(req: prepareSendRequest);
    },
    (err, stackTrace) => WalletError(
      WalletErrorType.transactionFailed,
      "Falha ao preparar transação de envio total L2: $err",
    ),
  );
}

TaskEither<WalletError, PrepareSendResponse> _prepareDrainAssetResponse(
  BreezSdkLiquid breez,
  String destination,
  Asset asset,
) {
  return TaskEither.tryCatch(
    () async {
      final balance = await breez.getInfo();
      final assetBalances = balance.walletInfo.assetBalances;

      double assetAmount = 0.0;
      for (final assetBalance in assetBalances) {
        if (assetBalance.assetId == asset.id) {
          assetAmount = assetBalance.balanceSat.toDouble() / 100000000;
          break;
        }
      }

      if (assetAmount <= 0) {
        throw Exception("Saldo insuficiente para o ativo ${asset.id}");
      }

      final prepareSendRequest = PrepareSendRequest(
        destination: destination,
        amount: PayAmount_Asset(
          toAsset: asset.id,
          receiverAmount: assetAmount,
          estimateAssetFees: true,
        ),
      );

      return await breez.prepareSendPayment(req: prepareSendRequest);
    },
    (err, stackTrace) => WalletError(
      WalletErrorType.transactionFailed,
      "Falha ao preparar transação de envio total de asset: $err",
    ),
  );
}

double _extractAssetAmount(PayAmount? payAmount) {
  if (payAmount == null) return 0.0;

  if (payAmount is PayAmount_Asset) {
    return payAmount.receiverAmount;
  }

  return 0.0;
}
