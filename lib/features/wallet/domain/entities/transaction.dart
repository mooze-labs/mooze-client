import 'package:mooze_mobile/shared/entities/asset.dart';
import '../enums/blockchain.dart';

enum TransactionType { send, receive, swap, redeposit, submarine, unknown }

enum TransactionStatus { pending, confirmed, failed, refundable }

class Transaction {
  final String id;
  final BigInt amount;
  final Blockchain blockchain;
  final Asset asset;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime createdAt;
  final Asset? fromAsset;
  final Asset? toAsset;
  final BigInt? sentAmount;
  final BigInt? receivedAmount;
  final String? sendTxId;
  final String? receiveTxId;
  final Blockchain? sendBlockchain;
  final Blockchain? receiveBlockchain;
  final int? confirmationHeight;
  final String? preimage;
  final String? blockchainUrl;
  final String? destination;

  Transaction({
    required this.id,
    required this.amount,
    required this.blockchain,
    required this.asset,
    required this.type,
    required this.status,
    required this.createdAt,
    this.fromAsset,
    this.toAsset,
    this.sentAmount,
    this.receivedAmount,
    this.sendTxId,
    this.receiveTxId,
    this.sendBlockchain,
    this.receiveBlockchain,
    this.confirmationHeight,
    this.preimage,
    this.blockchainUrl,
    this.destination,
  });

  @override
  String toString() {
    return 'Transaction{id: $id, amount: $amount, blockchain: $blockchain, asset: $asset, type: $type, status: $status, createdAt: $createdAt, fromAsset: $fromAsset, toAsset: $toAsset, sentAmount: $sentAmount, receivedAmount: $receivedAmount, sendTxId: $sendTxId, receiveTxId: $receiveTxId, sendBlockchain: $sendBlockchain, receiveBlockchain: $receiveBlockchain, confirmationHeight: $confirmationHeight, preimage: $preimage, blockchainUrl: $blockchainUrl, destination: $destination}';
  }
}
