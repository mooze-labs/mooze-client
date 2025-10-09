import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stream_transform/stream_transform.dart';

sealed class SyncState {}

class SyncIdle extends SyncState {}

class SyncInProgress extends SyncState {}

class SyncCompleted extends SyncState {
  final DateTime timestamp;
  SyncCompleted(this.timestamp);
}

class SyncFailed extends SyncState {
  final String error;
  SyncFailed(this.error);
}

abstract interface class SyncableDataSource {
  Future<void> sync();
}

TaskEither<String, Unit> syncDataSource(SyncableDataSource dataSource) {
  return TaskEither.tryCatch(() async {
    await dataSource.sync();
    return unit;
  }, (error, _) => "Sync failed: ${error.toString()}");
}

Stream<int> createPeriodicTicker(Duration interval) =>
    Stream.periodic(interval, (count) => count);

Stream<TaskEither<String, Unit>> createSyncCommands(
  Stream<int> ticker,
  SyncableDataSource dataSource,
) => ticker.map((_) => syncDataSource(dataSource));

SyncState reduceSyncState(SyncState current, Either<String, Unit> result) =>
    result.fold((err) => SyncFailed(err), (_) => SyncCompleted(DateTime.now()));

class SyncService {
  final StreamController<SyncState> _stateController =
      StreamController.broadcast();
  StreamSubscription? _syncSubscription;

  Stream<SyncState> get syncState => _stateController.stream;

  TaskEither<String, Unit> startPeriodicSync(
    SyncableDataSource dataSource,
    Duration interval,
  ) {
    debugPrint("[SyncService] Initializing");
    return TaskEither.tryCatch(() async {
      await stopPeriodicSync().run();

      // Trigger immediate sync on startup
      debugPrint("[SyncService] Triggering immediate initial sync");
      _stateController.add(SyncInProgress());
      final initialSync = await syncDataSource(dataSource).run();
      final initialState = reduceSyncState(SyncIdle(), initialSync);
      _stateController.add(initialState);
      debugPrint("[SyncService] Initial sync completed: ${initialState.runtimeType}");

      // Set up periodic syncs
      final ticker = createPeriodicTicker(interval);
      final syncCommands = createSyncCommands(ticker, dataSource);

      _syncSubscription = syncCommands
          .throttle(interval)
          .asyncMap((syncTask) async {
            debugPrint("[SyncService] Periodic sync triggered");
            _stateController.add(SyncInProgress());
            final result = await syncTask.run();
            final newState = reduceSyncState(SyncIdle(), result);
            _stateController.add(newState);
            return result;
          })
          .listen(null);
      return unit;
    }, (err, _) => "Failed to start sync service: ${err.toString()}");
  }

  TaskEither<String, Unit> stopPeriodicSync() => TaskEither.tryCatch(() async {
    await _syncSubscription?.cancel();
    _syncSubscription = null;
    return unit;
  }, (error, _) => "Failed to stop sync service: ${error.toString()}");

  void dispose() {
    _syncSubscription?.cancel();
    _stateController.close();
  }
}
