import 'package:fpdart/fpdart.dart';

import '../../../../domain/events/sync_outcome.dart';
import '../../../../domain/failures/failure.dart';
import '../../../sync/domain/sync_orchestrator.dart';
import '../../../sync/domain/sync_strategy.dart';

class RefreshWalletUseCase {
  RefreshWalletUseCase(this._sync);
  final SyncOrchestrator _sync;

  Future<Either<SyncFailure, SyncOutcome>> call({
    SyncStrategy strategy = SyncStrategy.light,
  }) =>
      _sync.refresh(strategy: strategy);
}
