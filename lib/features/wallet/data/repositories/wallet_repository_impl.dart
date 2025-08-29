import 'dart:math';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/data/dto/payment_request_dto.dart';
import 'package:mooze_mobile/features/wallet/data/dto/transaction_dto.dart';
import 'package:mooze_mobile/features/wallet/data/models/psbt_session.dart';

import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../dto/psbt_dto.dart';

class BreezWalletRepositoryImpl extends WalletRepository {
  final BindingLiquidSdk _breez;
  Map<String, PartiallySignedTransactionSession> _psbtSessions =
      {}; // cache of current send payment requests

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
    ).flatMap(
      (response) => TaskEither.right(
        BreezPreparedStablecoinTransactionDto(
          destination: destination,
          amount: amount,
          fees: response.feesSat ?? BigInt.zero,
          asset: asset.id,
        ).toDomain(),
      ),
    );
  }

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(String destination, BigInt amount) {
    return prepareOnchainSendTransaction(_breez, destination, amount).flatMap(
      (response) => TaskEither.right(
        BreezPreparedOnchainTransactionDto(
          destination: destination,
          fees: response.prepareResponse.totalFeesSat,
          amount: amount,
        ).toDomain(),
      ),
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLightningPaymentTransaction(String destination, BigInt amount) {
    return prepareLayer2BitcoinSendTransaction(
      _breez,
      destination,
      amount,
    ).flatMap(
      (response) => TaskEither.right(
        BreezPreparedLayer2TransactionDto(
          destination: destination,
          blockchain: Blockchain.lightning,
          fees: response.feesSat ?? BigInt.zero,
          amount: amount,
        ).toDomain(),
      ),
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount) {
    return prepareLayer2BitcoinSendTransaction(
      _breez,
      destination,
      amount,
    ).flatMap(
      (response) => TaskEither.right(
        BreezPreparedLayer2TransactionDto(
          destination: destination,
          blockchain: Blockchain.liquid,
          fees: response.feesSat ?? BigInt.zero,
          amount: amount,
        ).toDomain(),
      ),
    );
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
    ).flatMap(
      (preparedTransaction) =>
          sendLayer2Transaction(_breez, preparedTransaction).flatMap(
            (response) => TaskEither.right(
              BreezTransactionDto.fromSdk(payment: response.payment).toDomain(),
            ),
          ),
    );
  }

  @override
  TaskEither<WalletError, Transaction> sendL2BitcoinPayment(
    PreparedLayer2BitcoinTransaction psbt,
  ) {
    return prepareLayer2BitcoinSendTransaction(
      _breez,
      psbt.destination,
      psbt.amount,
    ).flatMap(
      (preparedTransaction) =>
          sendLayer2Transaction(_breez, preparedTransaction).flatMap(
            (response) => TaskEither.right(
              BreezTransactionDto.fromSdk(payment: response.payment).toDomain(),
            ),
          ),
    );
  }

  @override
  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  ) {
    return prepareOnchainSendTransaction(
      _breez,
      psbt.destination,
      psbt.amount,
    ).flatMap(
      (preparedTransaction) =>
          sendOnchainTransaction(_breez, preparedTransaction).flatMap(
            (response) => TaskEither.right(
              BreezTransactionDto.fromSdk(payment: response.payment).toDomain(),
            ),
          ),
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
      (err, stackTrace) => WalletError(
        WalletErrorType.networkError,
        "Falha ao ler transações: $err",
      ),
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
      (err, stackTrace) =>
          WalletError(WalletErrorType.networkError, "Falha ao ler saldo: %err"),
    );
  }

  PaymentMethod _getL2PaymentMethod(String destination) {
    final bolt11Regex = RegExp(r'^ln(bc|tb|bcrt)[0-9a-z]+$');
    final bolt12Regex = RegExp(r'^ln(o1|i1|r1)[0-9a-z]+$');

    if (bolt11Regex.hasMatch(destination)) {
      return PaymentMethod.bolt11Invoice;
    }

    if (bolt12Regex.hasMatch(destination)) {
      return PaymentMethod.bolt12Offer;
    }

    return PaymentMethod.liquidAddress;
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
    PaymentMethod.liquidAddress,
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
  return TaskEither.tryCatch(() async {
    return await breez.prepareReceivePayment(
      req: PrepareReceiveRequest(
        paymentMethod: paymentMethod,
        amount: recvAmount.fold(() => null, (amount) => amount),
      ),
    );
  }, (err, stackTrace) => WalletError(WalletErrorType.networkError));
}

TaskEither<WalletError, ReceivePaymentResponse> _receivePayment(
  BindingLiquidSdk breez,
  PrepareReceiveResponse prepareReceiveResponse,
  Option<String> description,
) {
  return TaskEither.tryCatch(
    () async {
      return await breez.receivePayment(
        req: ReceivePaymentRequest(
          prepareResponse: prepareReceiveResponse,
          description: description.fold(() => null, (desc) => desc),
        ),
      );
    },
    (err, stackTrace) => WalletError(
      WalletErrorType.transactionFailed,
      "Falha ao gerar endereço de pagamento",
    ),
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
    () async => breez.prepareSendPayment(req: prepareSendRequest),
    (err, stackTrace) => WalletError(
      WalletErrorType.transactionFailed,
      "Falha ao construir transação: $err",
    ),
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
    () async => breez.prepareSendPayment(req: sendRequest),
    (err, stackTrace) => WalletError(
      WalletErrorType.networkError,
      "Não foi possível preparar a transação: $err",
    ),
  );
}

TaskEither<WalletError, PayOnchainRequest> prepareOnchainSendTransaction(
  BindingLiquidSdk breez,
  String destination,
  BigInt amount,
) {
  return _getOnchainPaymentLimits(breez).flatMap((limits) {
    if (amount < limits.send.minSat)
      return TaskEither.left(
        WalletError(
          WalletErrorType.invalidAmount,
          "Valor insuficiente. Mínimo: ${limits.send.minSat} sats",
        ),
      );
    if (amount > limits.send.maxSat)
      return TaskEither.left(
        WalletError(
          WalletErrorType.invalidAmount,
          "Valor inválido. Máximo: ${limits.send.maxSat} sats",
        ),
      );

    return _preparePayOnchainResponse(breez, amount).flatMap(
      (r) => TaskEither.right(
        PayOnchainRequest(address: destination, prepareResponse: r),
      ),
    );
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

TaskEither<WalletError, SendPaymentResponse> sendLayer2Transaction(
  BindingLiquidSdk breez,
  PrepareSendResponse psbt,
) {
  return TaskEither.tryCatch(
    () async {
      return await breez.sendPayment(
        req: SendPaymentRequest(prepareResponse: psbt),
      );
    },
    (err, stackTrace) => WalletError(
      WalletErrorType.transactionFailed,
      "Transação falhou: [BREEZ] $err",
    ),
  );
}

TaskEither<WalletError, SendPaymentResponse> sendOnchainTransaction(
  BindingLiquidSdk breez,
  PayOnchainRequest psbt,
) {
  return TaskEither.tryCatch(
    () async {
      return await breez.payOnchain(req: psbt);
    },
    (err, stackTrace) => WalletError(
      WalletErrorType.transactionFailed,
      "Transação falhou: [BREEZ] $err",
    ),
  );
}
