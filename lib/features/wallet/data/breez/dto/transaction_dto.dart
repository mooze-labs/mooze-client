import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';

import '../../../domain/enums/asset.dart';

const lBtcAssetId =
    "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d";

class BreezTransactionDto {
  final String id;
  final String destination;
  final PaymentType paymentType;
  final BigInt amount;
  final BigInt fees;
  final Asset asset;
  final Blockchain blockchain;
  final TransactionStatus status;

  BreezTransactionDto({
    required this.id,
    required this.paymentType,
    required this.amount,
    required this.fees,
    required this.asset,
    required this.destination,
    required this.blockchain,
    required this.status,
  });

  factory BreezTransactionDto.fromSdk({required SendPaymentResponse response}) {
    final payment = response.payment;
    final asset = switch (payment.details) {
      PaymentDetails_Lightning() => Asset.btc,
      PaymentDetails_Bitcoin() => Asset.btc,
      PaymentDetails_Liquid() =>
        (payment.details as PaymentDetails_Liquid).assetId == lBtcAssetId
            ? Asset.btc
            : Asset.fromId((payment.details as PaymentDetails_Liquid).assetId),
    };

    final String destination = _parseDestination(payment);

    final String txid = _parseTxid(payment);

    return BreezTransactionDto(
      id: txid,
      destination: destination,
      paymentType: payment.paymentType,
      amount: payment.amountSat,
      fees: payment.feesSat,
      asset: asset,
      blockchain: _parseBlockchain(payment),
      status: _parseStatus(payment),
    );
  }

  Transaction toDomain() {
    return Transaction(
      id: id,
      amount: amount,
      blockchain: blockchain,
      asset: asset,
      type:
          (paymentType == PaymentType.send)
              ? TransactionType.send
              : TransactionType.receive,
      status: status,
    );
  }

  static TransactionStatus _parseStatus(Payment payment) {
    if (payment.status == PaymentState.pending ||
        payment.status == PaymentState.waitingFeeAcceptance) {
      return TransactionStatus.pending;
    }

    if (payment.status == PaymentState.refundPending ||
        payment.status == PaymentState.refundable) {
      return TransactionStatus.refundable;
    }

    if (payment.status == PaymentState.complete) {
      return TransactionStatus.confirmed;
    }

    return TransactionStatus.failed;
  }

  static String _parseDestination(Payment payment) {
    final details = payment.details;

    if (details is PaymentDetails_Lightning) {
      if (details.bolt12Offer != null) {
        return details.bolt12Offer!;
      }

      if (details.invoice != null) {
        return details.invoice!;
      }

      return details.swapId; // fallback
    }

    if (details is PaymentDetails_Bitcoin) {
      return details.bitcoinAddress;
    }

    if (details is PaymentDetails_Liquid) {
      return details.destination;
    }

    throw Exception('Unknown payment details type');
  }

  static String _parseTxid(Payment payment) {
    final details = payment.details;

    if (details is PaymentDetails_Lightning) {
      if (details.claimTxId != null) {
        return details.claimTxId!;
      }

      return details.swapId;
    }

    if (details is PaymentDetails_Bitcoin) {
      if (details.claimTxId != null) {
        return details.claimTxId!;
      }

      return details.swapId;
    }

    if (details is PaymentDetails_Liquid) {
      if (payment.txId != null) {
        return payment.txId!;
      }

      return ''; // fallback
    }

    throw Exception('Unknown payment details type');
  }

  static Blockchain _parseBlockchain(Payment payment) {
    final details = payment.details;

    if (details is PaymentDetails_Lightning) {
      return Blockchain.lightning;
    }

    if (details is PaymentDetails_Bitcoin) {
      return Blockchain.bitcoin;
    }

    if (details is PaymentDetails_Liquid) {
      return Blockchain.liquid;
    }

    throw Exception('Unknown payment details type');
  }
}
