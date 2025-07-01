import 'dart:math';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/data/breez/dto/payment_request_dto.dart';
import 'package:mooze_mobile/features/wallet/data/breez/dto/transaction_dto.dart';
import 'package:mooze_mobile/features/wallet/data/breez/models/prepared_transaction.dart';
import 'package:mooze_mobile/features/wallet/data/breez/models/psbt_session.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/limit.dart';

import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';

import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';

import './dto/psbt_dto.dart';

class BreezWalletRepositoryImpl extends WalletRepository {
  final BindingLiquidSdk _breez;
  Map<String, PartiallySignedTransactionSession> _psbtSessions =
      {}; // cache of current send payment requests

  BreezWalletRepositoryImpl(this._breez);

  @override
  Future<PaymentRequest> createInvoice(
    Asset asset,
    Blockchain blockchain,
    BigInt? amount,
    String? description,
  ) async {
    if (asset != Asset.btc) {
      if (blockchain != Blockchain.liquid) {
        throw ArgumentError('Custom assets are only supported on Liquid.');
      }

      return await _createAssetPaymentRequest(
        Asset.toId(asset),
        amount,
        description,
      );
    }

    if (blockchain == Blockchain.bitcoin) {
      return await _createOnchainBitcoinPaymentRequest(amount, description);
    }

    if (blockchain == Blockchain.lightning) {
      return await _createLightningPaymentRequest(amount, description);
    }

    return await _createLiquidBitcoinPaymentRequest(amount, description);
  }

  @override
  Future<PartiallySignedTransaction> buildTransaction(
    String destination,
    Asset asset,
    BigInt? amount,
    Blockchain blockchain,
  ) async {
    if (asset != Asset.btc) {
      if (amount == null) {
        throw ArgumentError('Amount is required for asset transactions');
      }

      return await _buildAssetTransaction(destination, asset, amount);
    }

    return await _buildBitcoinTransaction(destination, amount, blockchain);
  }

  @override
  Future<Transaction> sendPayment(PartiallySignedTransaction psbt) async {
    final session = _psbtSessions[psbt.id];

    if (session == null) {
      throw ArgumentError('Transaction not found');
    }

    final preparedTransaction = session.psbt;

    final response = switch (preparedTransaction) {
      L2Psbt(res: final res) => await _breez.sendPayment(
        req: SendPaymentRequest(prepareResponse: res),
      ),
      OnchainPsbt(res: final res) => await _breez.payOnchain(
        req: PayOnchainRequest(address: psbt.recipient, prepareResponse: res),
      ),
    };

    _psbtSessions.remove(psbt.id);

    return BreezTransactionDto.fromSdk(payment: response.payment).toDomain();
  }

  @override
  Future<List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

    final transactions = await _breez.listPayments(
      req: ListPaymentsRequest(
        fromTimestamp: startDate?.millisecondsSinceEpoch,
        toTimestamp: endDate?.millisecondsSinceEpoch,
        offset: 0,
        limit: 20,
        filters: paymentType,
        states: states,
      ),
    );

    return transactions
        .map((e) => BreezTransactionDto.fromSdk(payment: e).toDomain())
        .toList();
  }

  @override
  Future<Balance> getBalance() async {
    final info = await _breez.getInfo();
    final bitcoinBalance = info.walletInfo.balanceSat;
    final assetBalances = info.walletInfo.assetBalances;
    Balance balances = {};

    for (final assetBalance in assetBalances) {
      balances[Asset.fromId(assetBalance.assetId)] = assetBalance.balanceSat;
    }

    balances[Asset.btc] = bitcoinBalance;

    return balances;
  }

  Future<PaymentRequest> _createLiquidBitcoinPaymentRequest(
    BigInt? amount,
    String? description,
  ) async {
    final optionalAmount =
        (amount != null) ? ReceiveAmount_Bitcoin(payerAmountSat: amount) : null;

    final prepareReceivePayment = await _breez.prepareReceivePayment(
      req: PrepareReceiveRequest(
        paymentMethod: PaymentMethod.liquidAddress,
        amount: optionalAmount,
      ),
    );

    final ReceivePaymentResponse res = await _breez.receivePayment(
      req: ReceivePaymentRequest(
        prepareResponse: prepareReceivePayment,
        description: description,
      ),
    );

    return BreezPaymentRequestDto.fromBitcoin(
      paymentResponse: res,
      paymentMethod: PaymentMethod.liquidAddress,
      feesSat: prepareReceivePayment.feesSat,
      amount: optionalAmount,
      description: description,
    ).toDomain();
  }

  Future<PaymentRequest> _createLightningPaymentRequest(
    BigInt? amount,
    String? description,
  ) async {
    if (amount == null) {
      throw ArgumentError('Amount is required for lightning invoices');
    }

    final optionalAmount = ReceiveAmount_Bitcoin(payerAmountSat: amount);

    final prepareReceivePayment = await _breez.prepareReceivePayment(
      req: PrepareReceiveRequest(
        paymentMethod: PaymentMethod.lightning,
        amount: optionalAmount,
      ),
    );

    final ReceivePaymentResponse res = await _breez.receivePayment(
      req: ReceivePaymentRequest(
        prepareResponse: prepareReceivePayment,
        description: description,
      ),
    );

    return BreezPaymentRequestDto.fromBitcoin(
      paymentResponse: res,
      paymentMethod: PaymentMethod.lightning,
      feesSat: prepareReceivePayment.feesSat,
      amount: optionalAmount,
      description: description,
    ).toDomain();
  }

  Future<PaymentRequest> _createOnchainBitcoinPaymentRequest(
    BigInt? amount,
    String? description,
  ) async {
    final optionalAmount =
        (amount != null) ? ReceiveAmount_Bitcoin(payerAmountSat: amount) : null;
    final prepareReceivePayment = await _breez.prepareReceivePayment(
      req: PrepareReceiveRequest(
        paymentMethod: PaymentMethod.bitcoinAddress,
        amount: optionalAmount,
      ),
    );

    final ReceivePaymentResponse res = await _breez.receivePayment(
      req: ReceivePaymentRequest(
        prepareResponse: prepareReceivePayment,
        description: description,
      ),
    );

    return BreezPaymentRequestDto.fromBitcoin(
      paymentResponse: res,
      paymentMethod: PaymentMethod.bitcoinAddress,
      feesSat: prepareReceivePayment.feesSat,
      amount: optionalAmount,
      description: description,
    ).toDomain();
  }

  Future<PaymentRequest> _createAssetPaymentRequest(
    String assetId,
    BigInt? amount,
    String? description,
  ) async {
    final assetAmount =
        (amount != null) ? (amount.toInt() / pow(10, 8)).toDouble() : null;
    final recvAmount = ReceiveAmount_Asset(
      assetId: assetId,
      payerAmount: assetAmount,
    );

    final prepareReceivePayment = await _breez.prepareReceivePayment(
      req: PrepareReceiveRequest(
        paymentMethod: PaymentMethod.liquidAddress,
        amount: recvAmount,
      ),
    );

    final ReceivePaymentResponse res = await _breez.receivePayment(
      req: ReceivePaymentRequest(
        prepareResponse: prepareReceivePayment,
        description: description,
      ),
    );

    return BreezPaymentRequestDto.fromAsset(
      paymentResponse: res,
      amount: recvAmount,
      feesSat: prepareReceivePayment.feesSat,
      description: description,
    ).toDomain();
  }

  Future<PartiallySignedTransaction> _buildAssetTransaction(
    String destination,
    Asset asset,
    BigInt amount,
  ) async {
    final PayAmount_Asset optAmount = PayAmount_Asset(
      assetId: Asset.toId(asset),
      receiverAmount: (amount.toInt() / pow(10, 8)).toDouble(),
      estimateAssetFees: false,
    );

    final PrepareSendRequest prepareSendRequest = PrepareSendRequest(
      destination: destination,
      amount: optAmount,
    );

    final PrepareSendResponse prepareSendResponse = await _breez
        .prepareSendPayment(req: prepareSendRequest);

    final id = "l2-${asset.name}-${DateTime.now().millisecondsSinceEpoch}";

    _psbtSessions[id] = PartiallySignedTransactionSession(
      psbt: L2Psbt(prepareSendResponse),
      expireAt:
          DateTime.now()
              .add(const Duration(seconds: 300))
              .millisecondsSinceEpoch,
    );

    return BreezPartiallySignedTransactionDto.fromL2(
      id: id,
      prepareSendResponse: prepareSendResponse,
      paymentMethod: PaymentMethod.liquidAddress,
    ).toDomain();
  }

  Future<PartiallySignedTransaction> _buildBitcoinTransaction(
    String destination,
    BigInt? amount,
    Blockchain blockchain,
  ) async {
    if (blockchain != Blockchain.lightning && amount == null) {
      throw ArgumentError('Amount is required for non-lightning transactions');
    }

    if (blockchain == Blockchain.bitcoin) {
      return await _buildOnchainBitcoinTransaction(destination, amount!);
    }

    final id = "l2-${blockchain.name}-${DateTime.now().millisecondsSinceEpoch}";
    final optAmount =
        (amount != null) ? PayAmount_Bitcoin(receiverAmountSat: amount) : null;

    final PrepareSendResponse prepareSendResponse = await _breez
        .prepareSendPayment(
          req: PrepareSendRequest(destination: destination, amount: optAmount),
        );

    _psbtSessions[id] = PartiallySignedTransactionSession(
      psbt: L2Psbt(prepareSendResponse),
      expireAt:
          DateTime.now()
              .add(const Duration(seconds: 300))
              .millisecondsSinceEpoch,
    );

    return BreezPartiallySignedTransactionDto.fromL2(
      id: id,
      prepareSendResponse: prepareSendResponse,
      paymentMethod: _getL2PaymentMethod(destination),
    ).toDomain();
  }

  Future<PartiallySignedTransaction> _buildOnchainBitcoinTransaction(
    String destination,
    BigInt amount,
  ) async {
    OnchainPaymentLimitsResponse currentLimits =
        await _breez.fetchOnchainLimits();

    if (amount < currentLimits.send.minSat) {
      throw ArgumentError('Amount is too small');
    }

    if (amount > currentLimits.send.maxSat) {
      throw ArgumentError('Amount is too large');
    }

    final PreparePayOnchainResponse res = await _breez.preparePayOnchain(
      req: PreparePayOnchainRequest(
        amount: PayAmount_Bitcoin(receiverAmountSat: amount),
      ),
    );

    final PayOnchainRequest req = PayOnchainRequest(
      address: destination,
      prepareResponse: res,
    );

    final id = "onchain-${DateTime.now().millisecondsSinceEpoch}";
    _psbtSessions[id] = PartiallySignedTransactionSession(
      psbt: OnchainPsbt(res),
      expireAt:
          DateTime.now()
              .add(const Duration(seconds: 300))
              .millisecondsSinceEpoch,
    );

    return BreezPartiallySignedTransactionDto.fromOnchain(
      id: id,
      preparePayOnchainResponse: res,
      request: req,
    ).toDomain();
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
