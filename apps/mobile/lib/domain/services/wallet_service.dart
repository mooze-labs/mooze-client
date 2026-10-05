import 'package:fpdart/fpdart.dart';

import '../entities/balance.dart';
import '../entities/chain.dart';
import '../entities/transaction.dart';
import '../entities/wallet_credentials.dart';
import '../events/sync_outcome.dart';
import '../events/transaction_event.dart';
import '../failures/failure.dart';
import '../types/disposable.dart';
import 'service_state.dart';

/// Common contract every chain service satisfies. The sync orchestrator
/// iterates over a list of these without caring which chain it touches.
abstract interface class WalletService implements Disposable {
  ChainId get chain;

  Stream<ServiceState> get state;
  ServiceState get currentState;

  Future<Either<ServiceFailure, Unit>> connect(WalletCredentials credentials);
  Future<Either<ServiceFailure, Unit>> disconnect();

  Future<Either<ServiceFailure, SyncOutcome>> sync({Duration? timeout});

  Stream<TransactionEvent> get transactions;

  Future<Either<ServiceFailure, List<Transaction>>> listTransactions();
  Future<Either<ServiceFailure, Balance>> getBalance();
}
