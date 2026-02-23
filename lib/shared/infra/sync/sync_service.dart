import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

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
  AppLoggerService? _logger;

  Stream<SyncState> get syncState => _stateController.stream;

  /// Sets the logger instance for this service
  void setLogger(AppLoggerService logger) {
    _logger = logger;
  }

  TaskEither<String, Unit> startPeriodicSync(
    SyncableDataSource dataSource,
    Duration interval,
  ) {
    _logger?.info(
      'SyncService',
      'Initializing sync service with interval: ${interval.inMinutes}min',
    );
    return TaskEither.tryCatch(
      () async {
        await stopPeriodicSync().run();

        // Trigger immediate sync on startup
        _logger?.info('SyncService', 'Triggering immediate initial sync...');
        _stateController.add(SyncInProgress());
        final initialSync = await syncDataSource(dataSource).run();
        final initialState = reduceSyncState(SyncIdle(), initialSync);
        _stateController.add(initialState);
        _logger?.info(
          'SyncService',
          'Initial sync completed: ${initialState.runtimeType}',
        );

        // Set up periodic syncs
        final ticker = createPeriodicTicker(interval);
        final syncCommands = createSyncCommands(ticker, dataSource);

        _syncSubscription = syncCommands
            .throttle(interval)
            .asyncMap((syncTask) async {
              _logger?.debug('SyncService', 'Periodic sync triggered');
              _stateController.add(SyncInProgress());
              final result = await syncTask.run();
              final newState = reduceSyncState(SyncIdle(), result);
              _stateController.add(newState);

              if (newState is SyncFailed) {
                _logger?.error(
                  'SyncService',
                  'Periodic sync failed',
                  error: newState.error,
                );
              } else {
                _logger?.debug(
                  'SyncService',
                  'Periodic sync completed successfully',
                );
              }

              return result;
            })
            .listen(null);
        return unit;
      },
      (err, _) {
        _logger?.error(
          'SyncService',
          'Failed to start sync service',
          error: err,
        );
        return "Failed to start sync service: ${err.toString()}";
      },
    );
  }

  TaskEither<String, Unit> stopPeriodicSync() => TaskEither.tryCatch(
    () async {
      _logger?.info('SyncService', 'Stopping periodic sync...');
      await _syncSubscription?.cancel();
      _syncSubscription = null;
      _logger?.debug('SyncService', 'Periodic sync stopped');
      return unit;
    },
    (error, _) {
      _logger?.error(
        'SyncService',
        'Failed to stop sync service',
        error: error,
      );
      return "Failed to stop sync service: ${error.toString()}";
    },
  );

  void dispose() {
    _logger?.debug('SyncService', 'Disposing sync service');
    _syncSubscription?.cancel();
    _stateController.close();
  }
}
