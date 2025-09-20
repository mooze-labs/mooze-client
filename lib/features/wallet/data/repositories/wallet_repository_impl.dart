import 'dart:math';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/data/dto/payment_request_dto.dart';
import 'package:mooze_mobile/features/wallet/data/dto/transaction_dto.dart';

import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../dto/psbt_dto.dart';

class BreezWalletRepositoryImpl extends LiquidWalletRepository {
  final BindingLiquidSdk _breez;

  BreezWalletRepositoryImpl(this._breez);

  @override
  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _createOnchainBitcoinPaymentRequest(_breez, amount, description);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLightningInvoice(
    BigInt amount,
    Option<String> description,
  ) {
    return _createLightningPaymentRequest(_breez, amount, description);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLiquidBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _createLiquidBitcoinPaymentRequest(_breez, amount, description);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createStablecoinInvoice(
    Asset asset,
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _createAssetPaymentRequest(_breez, asset.id, amount, description);
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildStablecoinPaymentTransaction(
    String destination,
    Asset asset,
    double amount,
  ) {
    return prepareAssetSendTransaction(
      _breez,
      destination,
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

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(String destination, BigInt amount) {
    return prepareOnchainSendTransaction(_breez, destination, amount).flatMap((
      response,
    ) {
      return TaskEither.right(
        BreezPreparedOnchainTransactionDto(
          destination: destination,
          fees: response.prepareResponse.totalFeesSat,
          amount: amount,
        ).toDomain(),
      );
    });
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLightningPaymentTransaction(String destination, BigInt amount) {
    return prepareLightningTransaction(_breez, destination, amount).flatMap((
      response,
    ) {
      return TaskEither.right(
        BreezPreparedLayer2TransactionDto(
          destination: destination,
          blockchain: Blockchain.lightning,
          fees: response.feesSat,
          amount: amount,
        ).toDomain(),
      );
    });
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount) {
    return prepareLayer2BitcoinSendTransaction(
      _breez,
      destination,
      amount,
    ).flatMap((response) {
      return TaskEither.right(
        BreezPreparedLayer2TransactionDto(
          destination: destination,
          blockchain: Blockchain.liquid,
          fees: response.feesSat ?? BigInt.zero,
          amount: amount,
        ).toDomain(),
      );
    });
  }

  @override
  TaskEither<WalletError, Transaction> sendStablecoinPayment(
    PreparedStablecoinTransaction psbt,
  ) {
    return prepareAssetSendTransaction(
      _breez,
      psbt.destination,
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

  @override
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
        // Handle regular Lightning payments (LNURL-pay only)
        return sendLightningPayment(
          _breez,
          psbt.destination,
          psbt.amount,
        ).flatMap((response) {
          return TaskEither.right(
            BreezTransactionDto.fromSdk(
              payment: response.data.payment,
            ).toDomain(),
          );
        });
      }
    } else {
      // Handle Liquid payments
      return prepareLayer2BitcoinSendTransaction(
        _breez,
        psbt.destination,
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

  @override
  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  ) {
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

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildDrainOnchainBitcoinTransaction(String destination) {
    return getBalance().flatMap((balance) {
      return _prepareDrainOnchainResponse(_breez, destination).flatMap(
        (response) => TaskEither.right(
          BreezPreparedOnchainTransactionDto(
            destination: destination,
            fees: response.prepareResponse.totalFeesSat,
            amount: response.prepareResponse.receiverAmountSat,
          ).toDomain(),
        ),
      );
    });
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLightningTransaction(String destination) {
    return getBalance().flatMap((balance) {
      return _prepareDrainLightningResponse(_breez, destination).flatMap((
        response,
      ) {
        return TaskEither.right(
          BreezPreparedLayer2TransactionDto(
            destination: destination,
            blockchain: Blockchain.lightning,
            fees: response.feesSat,
            amount:
                BigInt
                    .zero, // For drain transactions, amount is determined by the prepare response
          ).toDomain(),
        );
      });
    });
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLiquidBitcoinTransaction(String destination) {
    return getBalance().flatMap((balance) {
      return _prepareDrainLayer2Response(
        _breez,
        destination,
        Blockchain.liquid,
      ).flatMap((response) {
        return TaskEither.right(
          BreezPreparedLayer2TransactionDto(
            destination: destination,
            blockchain: Blockchain.liquid,
            fees: response.feesSat ?? BigInt.zero,
            amount: response.exchangeAmountSat ?? BigInt.zero,
          ).toDomain(),
        );
      });
    });
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildDrainStablecoinTransaction(String destination, Asset asset) {
    return getBalance().flatMap((balance) {
      return _prepareDrainAssetResponse(_breez, destination, asset).flatMap(
        (response) => TaskEither.right(
          BreezPreparedStablecoinTransactionDto(
            destination: destination,
            amount: _extractAssetAmount(response.amount),
            fees: response.feesSat ?? BigInt.zero,
            asset: Asset.toId(asset),
          ).toDomain(),
        ),
      );
    });
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

  @override
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

        balances[Asset.btc] = bitcoinBalance;

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

/// RECEIVE functions
TaskEither<WalletError, PaymentRequest> _createLiquidBitcoinPaymentRequest(
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
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
// Functions receive BindingLiquidSdk as a parameter.
// This is to keep the functions as pure as possible.

TaskEither<WalletError, PrepareSendResponse> prepareAssetSendTransaction(
  BindingLiquidSdk breez,
  String destination,
  Asset asset,
  double amount,
) {
  final PayAmount_Asset payAmount = PayAmount_Asset(
    toAsset: Asset.toId(asset),
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
  BindingLiquidSdk breez,
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

// Lightning payment preparation - uses prepareLnurlPay directly for cleaner implementation
TaskEither<WalletError, PrepareLnUrlPayResponse> prepareLightningTransaction(
  BindingLiquidSdk breez,
  String destination,
  BigInt amount,
) {
  return TaskEither.tryCatch(
    () async {
      // Parse the destination to determine the input type
      final inputType = await breez.parse(input: destination);

      if (inputType is InputType_LnUrlPay) {
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
      } else {
        throw Exception(
          'Regular lightning invoices not supported in this method. Use prepareLayer2BitcoinSendTransaction instead.',
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
  BindingLiquidSdk breez,
  String destination,
  BigInt amount,
) {
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

    return _preparePayOnchainResponse(breez, amount).flatMap((r) {
      return TaskEither.right(
        PayOnchainRequest(address: destination, prepareResponse: r),
      );
    });
  });
}

TaskEither<WalletError, PreparePayOnchainResponse> _preparePayOnchainResponse(
  BindingLiquidSdk breez,
  BigInt amount,
) {
  return TaskEither.tryCatch(
    () async => breez.preparePayOnchain(
      req: PreparePayOnchainRequest(
        amount: PayAmount_Bitcoin(receiverAmountSat: amount),
      ),
    ),
    (err, stackTrace) => WalletError(
      WalletErrorType.transactionFailed,
      "Falha ao gerar transação: $err",
    ),
  );
}

TaskEither<WalletError, OnchainPaymentLimitsResponse> _getOnchainPaymentLimits(
  BindingLiquidSdk breez,
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
_sendDrainLightningPayment(BindingLiquidSdk breez, String destination) {
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
  BindingLiquidSdk breez,
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

TaskEither<WalletError, SendPaymentResponse> sendLayer2Transaction(
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
  String destination,
) {
  return TaskEither.tryCatch(
    () async {
      // For drain transactions, use PayAmount_Drain to send all available funds
      final prepareResponse = await breez.preparePayOnchain(
        req: PreparePayOnchainRequest(amount: PayAmount_Drain()),
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
  BindingLiquidSdk breez,
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
  BindingLiquidSdk breez,
  String destination,
  Asset asset,
) {
  return TaskEither.tryCatch(
    () async {
      final balance = await breez.getInfo();
      final assetBalances = balance.walletInfo.assetBalances;
      final assetId = Asset.toId(asset);

      double assetAmount = 0.0;
      for (final assetBalance in assetBalances) {
        if (assetBalance.assetId == assetId) {
          assetAmount = assetBalance.balanceSat.toDouble() / 100000000;
          break;
        }
      }

      if (assetAmount <= 0) {
        throw Exception("Saldo insuficiente para o ativo $assetId");
      }

      final prepareSendRequest = PrepareSendRequest(
        destination: destination,
        amount: PayAmount_Asset(
          toAsset: assetId,
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
