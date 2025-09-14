import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stream_transform/stream_transform.dart';
import '../wallet/datasource.dart';

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

TaskEither<String, Unit> syncLiquidWallet(LiquidDataSource dataSource) {
  return TaskEither.tryCatch(() async {
    await compute(_performSyncInIsolate, dataSource);
    return unit;
  }, (error, _) => "Sync failed: ${error.toString()}");
}

Future<void> _performSyncInIsolate(LiquidDataSource dataSource) async =>
    await dataSource.sync();

Stream<int> createPeriodicTicker(Duration interval) =>
    Stream.periodic(interval, (count) => count);
Stream<TaskEither<String, Unit>> createSyncCommands(
  Stream<int> ticker,
  LiquidDataSource dataSource,
) => ticker.map((_) => syncLiquidWallet(dataSource));

SyncState reduceSyncState(SyncState current, Either<String, Unit> result) =>
    result.fold((err) => SyncFailed(err), (_) => SyncCompleted(DateTime.now()));

class LwkSyncService {
  final StreamController<SyncState> _stateController =
      StreamController.broadcast();
  StreamSubscription? _syncSubscription;

  Stream<SyncState> get syncState => _stateController.stream;

  TaskEither<String, Unit> startPeriodicSync(
    LiquidDataSource dataSource,
    Duration interval,
  ) {
    return TaskEither.tryCatch(() async {
      await stopPeriodicSync().run();

      final ticker = createPeriodicTicker(interval);
      final syncCommands = createSyncCommands(ticker, dataSource);

      _syncSubscription = syncCommands
          .throttle(interval)
          .asyncMap((syncTask) async {
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
}
