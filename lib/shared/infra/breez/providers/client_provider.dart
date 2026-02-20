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
  'unable to open database',
  'database is locked',
  'storage.sql',
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

      logger.debug(
        'BreezClient',
        'Breez config workingDir: ${config.workingDir}',
      );

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final connectRequest = ConnectRequest(
            mnemonic: mnemonic,
            config: config,
          );

          logger.info(
            'BreezClient',
            'Attempting connection $attempt/$maxRetries...',
          );
          logger.debug(
            'BreezClient',
            'Using mnemonic: ${mnemonic.substring(0, 20)}...',
          );

          final client = await connect(req: connectRequest);
          logger.info('BreezClient', '✅ Breez SDK connected successfully');

          // Sync em background (fire and forget)
          _syncBreezInBackground(client, syncStream, logger, ref);

          return right(client);
        } catch (e) {
          final errorMessage = e.toString();

          // Handle database errors (unable to open, migration errors, etc.)
          final isDatabaseError =
              errorMessage.contains('unable to open database') ||
              errorMessage.contains('database is locked') ||
              errorMessage.contains('storage.sql') ||
              errorMessage.contains('rusqlite_migrate') ||
              errorMessage.contains('duplicate column name');

          if (isDatabaseError) {
            logger.warning(
              'BreezClient',
              'Database error detected on attempt $attempt: $errorMessage',
              error: e,
            );

            // Try to clean up the Breez directory before retrying
            try {
              final dbDir = Directory(config.workingDir);
              if (await dbDir.exists()) {
                logger.info(
                  'BreezClient',
                  'Cleaning Breez directory due to database error...',
                );
                await dbDir.delete(recursive: true);
                logger.info(
                  'BreezClient',
                  'Breez directory cleaned, waiting before retry...',
                );
                // Wait for filesystem to sync
                await Future.delayed(Duration(milliseconds: 500));
              }
            } catch (cleanupError) {
              logger.warning(
                'BreezClient',
                'Error cleaning directory: $cleanupError',
              );
            }

            // If this is not the last attempt, retry
            if (attempt < maxRetries) {
              final delay = initialDelay * attempt;
              logger.info(
                'BreezClient',
                'Retrying connection in ${delay.inSeconds}s after database cleanup...',
              );
              await Future.delayed(delay);
              continue;
            }

            // Last attempt with database error - try one more time with full cleanup
            logger.warning(
              'BreezClient',
              'Last attempt failed with database error, trying reconnection...',
            );

            try {
              final retryRequest = ConnectRequest(
                mnemonic: mnemonic,
                config: config,
              );
              final client = await connect(req: retryRequest);
              logger.info('BreezClient', 'Breez SDK reconnected after cleanup');

              // Try to sync after reconnection (non-blocking, with timeout)
              try {
                logger.info(
                  'BreezClient',
                  'Attempting sync after reconnection...',
                );
                await client.sync().timeout(
                  Duration(seconds: 30),
                  onTimeout: () {
                    logger.warning(
                      'BreezClient',
                      'Sync timeout after reconnection (non-critical)',
                    );
                    throw Exception('Sync timeout after 30s');
                  },
                );
                logger.info(
                  'BreezClient',
                  'Breez SDK synced after reconnection',
                );
              } catch (syncError) {
                logger.warning(
                  'BreezClient',
                  'Sync failed after reconnection (non-critical): $syncError',
                );
              }

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

  logger.info('BreezClient', 'Starting background sync with retry logic...');

  _syncBreezWithRetry(
        client: client,
        logger: logger,
        maxAttempts: 4, // Try up to 4 times
        initialDelay: Duration(seconds: 3),
      )
      .then((_) {
        logger.info('BreezClient', 'Background sync completed successfully');
        syncStream.updateProgress(
          SyncProgress(
            datasource: 'Breez',
            status: SyncStatus.completed,
            timestamp: DateTime.now(),
          ),
        );
        syncEventController.emitCompleted('breez');
      })
      .catchError((e, stack) {
        final errorMsg = e.toString();

        // Log differently based on error type
        if (_isRetryableError(errorMsg)) {
          logger.warning(
            'BreezClient',
            'Background sync failed after retries (temporary issue): $e',
            error: e,
          );
        } else {
          logger.error(
            'BreezClient',
            'Background sync failed: $e',
            error: e,
            stackTrace: stack,
          );
        }

        syncStream.updateProgress(
          SyncProgress(
            datasource: 'Breez',
            status: SyncStatus.error,
            errorMessage: errorMsg,
            timestamp: DateTime.now(),
          ),
        );
        syncEventController.emitFailed('breez', errorMsg);
      });
}

/// Performs Breez sync with exponential backoff retry logic
Future<void> _syncBreezWithRetry({
  required BreezSdkLiquid client,
  required AppLoggerService logger,
  required int maxAttempts,
  required Duration initialDelay,
}) async {
  String? lastError;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      logger.info('BreezClient', 'Sync attempt $attempt/$maxAttempts...');

      // Try sync with timeout
      await client.sync().timeout(
        Duration(seconds: 45),
        onTimeout: () {
          throw Exception('Breez sync timeout after 45s');
        },
      );

      // Success!
      logger.info('BreezClient', 'Sync successful on attempt $attempt');
      return;
    } catch (e) {
      lastError = e.toString();

      logger.warning(
        'BreezClient',
        'Sync attempt $attempt/$maxAttempts failed: $lastError',
      );

      // Check if this is a database-related error that needs directory cleanup
      final isDatabaseError =
          lastError.contains('unable to open database') ||
          lastError.contains('database is locked') ||
          lastError.contains('storage.sql') ||
          lastError.contains('rusqlite');

      // If it's a database error and not the last attempt, try cleanup
      if (isDatabaseError && attempt < maxAttempts) {
        logger.warning(
          'BreezClient',
          'Database error detected - this might need manual intervention',
        );
        // Note: Can't clean directory here since we don't have access to config
        // The cleanup should happen at connection time

        // Wait longer for database errors
        final delay = initialDelay * (attempt + 1);
        logger.info(
          'BreezClient',
          'Retrying in ${delay.inSeconds}s... (database error)',
        );
        await Future.delayed(delay);
        continue;
      }

      // If this is not the last attempt and error is retryable, wait and retry
      if (attempt < maxAttempts && _isRetryableError(lastError)) {
        // Exponential backoff: 3s, 6s, 12s, 24s
        final delay = initialDelay * (1 << (attempt - 1));
        logger.info(
          'BreezClient',
          'Retrying in ${delay.inSeconds}s... (retryable error detected)',
        );
        await Future.delayed(delay);
        continue;
      }

      // If this is not the last attempt, try one more time even if not officially retryable
      // Sometimes transient issues resolve themselves
      if (attempt < maxAttempts) {
        final delay = initialDelay * attempt;
        logger.info(
          'BreezClient',
          'Retrying in ${delay.inSeconds}s... (attempt $attempt/$maxAttempts)',
        );
        await Future.delayed(delay);
        continue;
      }

      // Last attempt failed - throw with full context
      throw Exception(
        'Breez sync failed after $maxAttempts attempts. Last error: $lastError',
      );
    }
  }

  // Should not reach here, but for safety
  throw Exception(
    'Breez sync failed after $maxAttempts attempts. Last error: $lastError',
  );
}
