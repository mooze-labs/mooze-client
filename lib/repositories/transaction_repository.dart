import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/transaction.dart';

abstract class TransactionRepository {
  Future<List<TransactionRecord>> getTransactions();
  Future<TransactionRecord> getTransaction(String txid);
  Future<void> newTransaction<T>(
    String txid,
    Asset asset,
    int amount,
    TransactionDirection direction,
    DateTime timestamp,
  );
}
