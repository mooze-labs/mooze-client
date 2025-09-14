import 'package:mooze_mobile/shared/entities/asset.dart';
import '../enums/blockchain.dart';

enum TransactionType { send, receive, swap }

enum TransactionStatus { pending, confirmed, failed, refundable }

class Transaction {
  final String id;
  final BigInt amount;
  final Blockchain blockchain;
  final Asset asset;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.blockchain,
    required this.asset,
    required this.type,
    required this.status,
    required this.createdAt,
  });
}
