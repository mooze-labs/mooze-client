import 'package:fpdart/fpdart.dart';

import '../../../domain/failures/failure.dart';
import '../../../domain/types/disposable.dart';
import 'boot_state.dart';

/// Owns the cold-start sequence end-to-end. Idempotent: concurrent or repeat
/// `start()` calls return the same outcome. `shutdown()` always succeeds (no
/// throws) and reverts services to disconnected.
abstract interface class BootOrchestrator implements Disposable {
  Stream<BootState> get state;
  BootState get currentState;
  Future<Either<BootFailure, BootState>> start();
  Future<void> shutdown();
}
