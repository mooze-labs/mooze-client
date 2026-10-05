import 'package:fpdart/fpdart.dart';

import '../../domain/failures/failure.dart';
import '../../domain/types/disposable.dart';
import 'app_state.dart';

/// Top-level coordinator. Owns the order: Boot → Sync.
abstract interface class AppLifecycleController implements Disposable {
  Stream<AppState> get state;
  AppState get currentState;
  Future<Either<Failure, AppState>> start();
  Future<void> shutdown();
  Future<Either<Failure, Unit>> deleteWalletAndReimport();
}
