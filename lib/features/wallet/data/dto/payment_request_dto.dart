import 'dart:math';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart'
    show
        ReceivePaymentResponse,
        ReceiveAmount_Bitcoin,
        ReceiveAmount_Asset,
        PaymentMethod;
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';

class BreezPaymentRequestDto {
  final String receiveAddress;
  final PaymentMethod paymentMethod;
  final BigInt fees;
  final String? assetId;
  final BigInt? amount;
  final String? description;

  BreezPaymentRequestDto({
    required this.receiveAddress,
    required this.paymentMethod,
    required this.fees,
    this.assetId,
    this.amount,
    this.description,
  });

  factory BreezPaymentRequestDto.fromBitcoin({
    required ReceivePaymentResponse paymentResponse,
    required PaymentMethod paymentMethod,
    required BigInt feesSat,
    required Option<BigInt> amount,
    required Option<String> description,
  }) {
    return BreezPaymentRequestDto(
      receiveAddress: paymentResponse.destination,
      paymentMethod: paymentMethod,
      amount: amount.fold(() => null, (amount) => amount),
      fees: feesSat,
      description: description.fold(() => null, (desc) => desc),
    );
  }

  factory BreezPaymentRequestDto.fromAsset({
    required ReceivePaymentResponse paymentResponse,
    required ReceiveAmount_Asset amount,
    required BigInt feesSat,
    String? description,
  }) {
    return BreezPaymentRequestDto(
      receiveAddress: paymentResponse.destination,
      paymentMethod: PaymentMethod.liquidAddress,
      assetId: amount.assetId,
      amount:
          (amount.payerAmount != null)
              ? BigInt.from(amount.payerAmount! / pow(10, 8))
              : null,
      fees: feesSat,
      description: description,
    );
  }

  factory BreezPaymentRequestDto.fromDomain(PaymentRequest paymentRequest) {
    final paymentMethod = switch (paymentRequest.blockchain) {
      Blockchain.lightning => PaymentMethod.bolt11Invoice,
      Blockchain.bitcoin => PaymentMethod.bitcoinAddress,
      Blockchain.liquid => PaymentMethod.liquidAddress,
    };

    return BreezPaymentRequestDto(
      receiveAddress: paymentRequest.address,
      paymentMethod: paymentMethod,
      fees: paymentRequest.fees,
      assetId: Asset.toId(paymentRequest.asset),
      amount: paymentRequest.amount,
      description: paymentRequest.description,
    );
  }

  PaymentRequest toDomain() {
    final blockchain = switch (paymentMethod) {
      PaymentMethod.lightning => Blockchain.lightning,
      PaymentMethod.bolt11Invoice => Blockchain.lightning,
      PaymentMethod.bolt12Offer => Blockchain.lightning,
      PaymentMethod.bitcoinAddress => Blockchain.bitcoin,
      PaymentMethod.liquidAddress => Blockchain.liquid,
    };

    final defaultAsset = switch (blockchain) {
      Blockchain.bitcoin => Asset.btc,
      Blockchain.liquid => Asset.lbtc,
      Blockchain.lightning => Asset.btc,
    };

    return PaymentRequest(
      address: receiveAddress,
      blockchain: blockchain,
      fees: fees,
      asset: assetId != null ? Asset.fromId(assetId!) : defaultAsset,
      amount: amount,
      description: description,
    );
  }
}
