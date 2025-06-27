import 'dart:math';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/asset.dart';

class BreezPartiallySignedTransactionDto {
  final String destination;
  final PaymentMethod paymentMethod;
  final BigInt amount;
  final BigInt fees;
  final String? asset;

  BreezPartiallySignedTransactionDto({
    required this.destination,
    required this.paymentMethod,
    required this.amount,
    required this.fees,
    this.asset,
  });

  factory BreezPartiallySignedTransactionDto.fromL2({
    required PrepareSendResponse prepareSendResponse,
    required PaymentMethod paymentMethod,
  }) {
    final destination = switch (prepareSendResponse.destination) {
      SendDestination_LiquidAddress() =>
        (prepareSendResponse.destination as SendDestination_LiquidAddress)
            .addressData
            .address,
      SendDestination_Bolt11() =>
        (prepareSendResponse.destination as SendDestination_Bolt11)
            .invoice
            .bolt11,
      SendDestination_Bolt12() =>
        (prepareSendResponse.destination as SendDestination_Bolt12).offer.offer,
    };

    final amount = switch (prepareSendResponse.amount) {
      PayAmount_Asset() => BigInt.from(
        (prepareSendResponse.amount as PayAmount_Asset).receiverAmount *
            pow(10, 8),
      ),
      PayAmount_Bitcoin() =>
        (prepareSendResponse.amount as PayAmount_Bitcoin).receiverAmountSat,
      _ => throw StateError("Amount is invalid."),
    };

    final asset = switch (prepareSendResponse.amount) {
      PayAmount_Asset() =>
        (prepareSendResponse.amount as PayAmount_Asset).assetId,
      PayAmount_Bitcoin() => null,
      _ => throw StateError("Asset is invalid"),
    };

    return BreezPartiallySignedTransactionDto(
      destination: destination,
      paymentMethod: paymentMethod,
      amount: amount,
      fees: prepareSendResponse.feesSat ?? BigInt.zero,
      asset: asset,
    );
  }

  factory BreezPartiallySignedTransactionDto.fromOnchain({
    required PreparePayOnchainResponse preparePayOnchainResponse,
    required PayOnchainRequest request,
  }) {
    final destination = request.address;
    final amount = request.prepareResponse.receiverAmountSat;

    return BreezPartiallySignedTransactionDto(
      destination: destination,
      paymentMethod: PaymentMethod.bitcoinAddress,
      amount: amount,
      fees: preparePayOnchainResponse.totalFeesSat,
    );
  }

  PartiallySignedTransaction toDomain() {
    return PartiallySignedTransaction(
      recipient: destination,
      asset: (asset != null) ? Asset.fromId(asset!) : Asset.btc,
      networkFees: fees,
      amount: amount,
    );
  }
}
