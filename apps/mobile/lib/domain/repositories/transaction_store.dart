import 'package:fpdart/fpdart.dart';

import '../entities/chain.dart';
import '../entities/transaction.dart';
import '../failures/failure.dart';

/// Single source of truth for persisted transactions across all chains.
/// Only the sync orchestrator writes here; everyone else watches.
abstract interface class TransactionStore {
  Future<Either<StorageFailure, Unit>> upsert(Transaction tx);
  Future<Either<StorageFailure, Unit>> upsertAll(List<Transaction> txs);
  Future<Either<StorageFailure, Transaction?>> findById(String id);
  Future<Either<StorageFailure, List<Transaction>>> list({
    ChainFilter? filter,
    int? limit,
  });
  Stream<List<Transaction>> watch({ChainFilter? filter});
  Future<Either<StorageFailure, Unit>> deleteAll();
}
