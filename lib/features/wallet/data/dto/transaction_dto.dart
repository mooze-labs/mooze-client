import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

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
  final DateTime createdAt;
  final String? preimage;
  final Payment payment; // Keep original payment for detailed info

  BreezTransactionDto({
    required this.id,
    required this.paymentType,
    required this.amount,
    required this.fees,
    required this.asset,
    required this.destination,
    required this.blockchain,
    required this.status,
    required this.createdAt,
    required this.payment,
    this.preimage,
  });

  factory BreezTransactionDto.fromSdk({required Payment payment}) {
    final asset = switch (payment.details) {
      PaymentDetails_Lightning() => Asset.lbtc,
      PaymentDetails_Bitcoin() => Asset.btc,
      PaymentDetails_Liquid() =>
        (payment.details as PaymentDetails_Liquid).assetId == lBtcAssetId
            ? Asset.lbtc
            : Asset.fromId((payment.details as PaymentDetails_Liquid).assetId),
    };

    final String destination = _parseDestination(payment);
    final String txid = _parseTxid(payment);
    final String? preimage = switch (payment.details) {
      PaymentDetails_Lightning() =>
        (payment.details as PaymentDetails_Lightning).preimage,
      _ => null,
    };

    // Breez SDK timestamp may come in seconds or milliseconds
    // Very small timestamps (< 10 billion) are in seconds
    final timestamp = payment.timestamp;
    final timestampMs = timestamp < 10000000000 ? timestamp * 1000 : timestamp;

    return BreezTransactionDto(
      id: txid,
      destination: destination,
      paymentType: payment.paymentType,
      amount: payment.amountSat,
      fees: payment.feesSat,
      asset: asset,
      blockchain: _parseBlockchain(payment),
      status: _parseStatus(payment),
      createdAt: DateTime.fromMillisecondsSinceEpoch(timestampMs.toInt()),
      payment: payment,
      preimage: preimage,
    );
  }

  Transaction toDomain() {
    final isSubmarineSwap = blockchain == Blockchain.bitcoin;

    String? blockchainUrl;
    if (id.isNotEmpty) {
      switch (blockchain) {
        case Blockchain.bitcoin:
          blockchainUrl = 'https://blockstream.info/tx/$id';
          break;
        case Blockchain.liquid:
          blockchainUrl = 'https://blockstream.info/liquid/tx/$id';
          break;
        case Blockchain.lightning:
          blockchainUrl = 'https://blockstream.info/liquid/tx/$id';
          break;
      }
    }

    // For submarine swaps, determine fromAsset and toAsset based on direction
    Asset? fromAsset;
    Asset? toAsset;
    BigInt? sentAmount;
    BigInt? receivedAmount;
    String? sendTxId;
    String? receiveTxId;
    Blockchain? sendBlockchain;
    Blockchain? receiveBlockchain;

    if (isSubmarineSwap) {
      // Get submarine swap details from payment
      final details = _getSubmarineSwapDetails();

      if (paymentType == PaymentType.send) {
        // Peg Out: Liquid → Bitcoin onchain
        fromAsset = Asset.lbtc;
        toAsset = Asset.btc;
        sentAmount = amount;
        receivedAmount = amount - fees; // Amount received after fees
        sendBlockchain = Blockchain.liquid;
        receiveBlockchain = Blockchain.bitcoin;

        // Handle refund case
        if (status == TransactionStatus.refundable &&
            details?.refundTxId != null) {
          sendTxId = details?.claimTxId; // Original Liquid transaction
          receiveTxId =
              details?.refundTxId; // Refund transaction (back to Liquid)
          // In refund case, funds go back to origin
          receiveBlockchain = Blockchain.liquid;
          toAsset = Asset.lbtc; // Funds return to Liquid
          receivedAmount = details?.refundTxAmountSat ?? (amount - fees);
        } else {
          sendTxId = details?.claimTxId; // Liquid transaction
          receiveTxId =
              details?.lockupTxId; // Bitcoin transaction (where funds arrive)
        }
      } else {
        // Peg In: Bitcoin onchain → Liquid
        fromAsset = Asset.btc;
        toAsset = Asset.lbtc;
        sentAmount = amount + fees; // Original amount sent including fees
        receivedAmount = amount; // Amount received (already deducted fees)
        sendBlockchain = Blockchain.bitcoin;
        receiveBlockchain = Blockchain.liquid;

        // Handle refund case
        if (status == TransactionStatus.refundable &&
            details?.refundTxId != null) {
          sendTxId = details?.lockupTxId; // Original Bitcoin transaction
          receiveTxId =
              details?.refundTxId; // Refund transaction (back to Bitcoin)
          // In refund case, funds go back to origin
          receiveBlockchain = Blockchain.bitcoin;
          toAsset = Asset.btc; // Funds return to Bitcoin
          receivedAmount = details?.refundTxAmountSat ?? (amount + fees);
        } else {
          sendTxId = details?.lockupTxId; // Bitcoin transaction
          receiveTxId =
              details?.claimTxId; // Liquid transaction (where funds arrive)
        }
      }
    }

    return Transaction(
      id: id,
      amount: amount,
      blockchain: blockchain,
      asset: asset,
      type:
          isSubmarineSwap
              ? TransactionType.submarine
              : (paymentType == PaymentType.send)
              ? TransactionType.send
              : TransactionType.receive,
      status: status,
      createdAt: createdAt,
      preimage: preimage,
      blockchainUrl: blockchainUrl,
      destination: destination,
      fromAsset: fromAsset,
      toAsset: toAsset,
      sentAmount: sentAmount,
      receivedAmount: receivedAmount,
      sendTxId: sendTxId,
      receiveTxId: receiveTxId,
      sendBlockchain: sendBlockchain,
      receiveBlockchain: receiveBlockchain,
    );
  }

  // Helper to get submarine swap details
  PaymentDetails_Bitcoin? _getSubmarineSwapDetails() {
    final details = payment.details;
    if (details is PaymentDetails_Bitcoin) {
      return details;
    }
    return null;
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

    if (payment.txId != null) return payment.txId!;

    if (details is PaymentDetails_Lightning) {
      return details.invoice ?? details.swapId;
    }

    if (details is PaymentDetails_Bitcoin) {
      return details.claimTxId ?? details.swapId;
    }

    if (details is PaymentDetails_Liquid) {
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
