import '../enums/asset.dart';
import '../enums/blockchain.dart';

enum TransactionType { send, receive, swap }

enum TransactionStatus { pending, confirmed, failed }

class Transaction {
  final String id;
  final int amount;
  final Blockchain blockchain;
  final Asset asset;
  final TransactionType type;
  final TransactionStatus status;

  Transaction({
    required this.id,
    required this.amount,
    required this.blockchain,
    required this.asset,
    required this.type,
    required this.status,
  });
}
