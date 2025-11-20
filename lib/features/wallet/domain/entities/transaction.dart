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
  });
}
