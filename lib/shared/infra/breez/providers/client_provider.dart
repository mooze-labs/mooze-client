import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_stream_controller.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_event_stream.dart';

import '../../../key_management/providers/mnemonic_provider.dart';
import 'config_provider.dart';

/// Temporary errors that can be resolved with retry
const _retryableErrors = [
  'Liquid tip not available',
  'network',
  'timeout',
  'connection',
  'temporarily unavailable',
];

/// Checks if the error is temporary and can be retried
bool _isRetryableError(String errorMessage) {
  final lowerError = errorMessage.toLowerCase();
  return _retryableErrors.any((e) => lowerError.contains(e.toLowerCase()));
}

final breezClientProvider = FutureProvider<Either<String, BreezSdkLiquid>>((
  ref,
) async {
  final logger = ref.read(appLoggerProvider);
  final config = await ref.read(configProvider.future);
  final mnemonicOption = await ref.watch(mnemonicProvider.future);
  final syncStream = ref.read(syncStreamProvider);

  return await mnemonicOption.fold(
    () async {
      logger.error(
        'BreezClient',
        'Mnemonic not available - wallet may not be initialized or mnemonic cache is stale',
      );
      return left('Mnemonic not available');
    },
    (mnemonic) async {
      const maxRetries = 3;
      const initialDelay = Duration(seconds: 2);

      logger.info(
        'BreezClient',
        'Starting Breez SDK connection (max retries: $maxRetries)',
      );

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final connectRequest = ConnectRequest(
            mnemonic: mnemonic,
            config: config,
          );

          logger.info(
            'BreezClient',
            'Connecting to Breez SDK... (attempt $attempt/$maxRetries)',
          );
          final client = await connect(req: connectRequest);
          logger.info('BreezClient', 'Breez SDK connected successfully');

          // Sync em background (fire and forget)
          _syncBreezInBackground(client, syncStream, logger, ref);

          return right(client);
        } catch (e) {
          final errorMessage = e.toString();

          // Handle database migration error
          if (errorMessage.contains('rusqlite_migrate') ||
              errorMessage.contains('duplicate column name')) {
            logger.warning(
              'BreezClient',
              'Database migration error detected, attempting cleanup',
              error: e,
            );
            try {
              final dbDir = Directory(config.workingDir);
              if (await dbDir.exists()) {
                logger.info(
                  'BreezClient',
                  'Deleting corrupted database directory',
                );
                await dbDir.delete(recursive: true);
              }

              final retryRequest = ConnectRequest(
                mnemonic: mnemonic,
                config: config,
              );
              logger.info(
                'BreezClient',
                'Reconnecting to Breez SDK after cleanup...',
              );
              final client = await connect(req: retryRequest);
              logger.info('BreezClient', 'Breez SDK reconnected successfully');

              // Sync after reconnection as well
              logger.info('BreezClient', 'Syncing after reconnection...');
              await client.sync();
              logger.info('BreezClient', 'Breez SDK synced after reconnection');

              return right(client);
            } catch (retryError) {
              logger.error(
                'BreezClient',
                'Failed to reconnect after database cleanup',
                error: retryError,
              );
              return left(
                'Failed to connect to Breez SDK after database cleanup: ${retryError.toString()}',
              );
            }
          }

          // For temporary errors, retry with exponential backoff
          if (_isRetryableError(errorMessage) && attempt < maxRetries) {
            final delay = initialDelay * (1 << (attempt - 1)); // 2s, 4s, 8s
            logger.warning(
              'BreezClient',
              'Temporary error detected. Retrying in ${delay.inSeconds}s...',
              error: e,
            );
            await Future.delayed(delay);
            continue;
          }

          // Unrecoverable error or last attempt
          logger.error(
            'BreezClient',
            'Failed to connect to Breez SDK',
            error: e,
          );
          return left('Failed to connect to Breez SDK: $errorMessage');
        }
      }

      // Should not reach here, but for safety
      final stackTrace = StackTrace.current;
      logger.critical(
        'BreezClient',
        'Exhausted all retry attempts without success',
        stackTrace: stackTrace,
      );
      return left('Failed to connect to Breez SDK after $maxRetries attempts');
    },
  );
});

void _syncBreezInBackground(
  BreezSdkLiquid client,
  SyncStreamController syncStream,
  AppLoggerService logger,
  Ref ref,
) {
  syncStream.updateProgress(
    SyncProgress(
      datasource: 'Breez',
      status: SyncStatus.syncing,
      timestamp: DateTime.now(),
    ),
  );

  final syncEventController = ref.read(syncEventControllerProvider);
  syncEventController.emitStarted('breez');

  logger.info('BreezClient', 'Starting background sync...');

  // Fire and forget - usa then/catchError em vez de await
  client
      .sync()
      .then((_) {
        logger.info('BreezClient', 'Background sync completed successfully');
        syncStream.updateProgress(
          SyncProgress(
            datasource: 'Breez',
            status: SyncStatus.completed,
            timestamp: DateTime.now(),
          ),
        );

        // Emite evento de conclusão
        syncEventController.emitCompleted('breez');
      })
      .catchError((e, stack) {
        logger.error(
          'BreezClient',
          'Background sync failed: $e',
          error: e,
          stackTrace: stack,
        );
        syncStream.updateProgress(
          SyncProgress(
            datasource: 'Breez',
            status: SyncStatus.error,
            errorMessage: e.toString(),
            timestamp: DateTime.now(),
          ),
        );

        syncEventController.emitFailed('breez', e.toString());
      });
}
