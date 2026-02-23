import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_stream_controller.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_event_stream.dart';
import 'package:path_provider/path_provider.dart';

import '../../../key_management/providers/mnemonic_provider.dart';
import 'config_provider.dart';

/// Global reference to the current Breez client for cleanup purposes
/// This is necessary because Riverpod's invalidate() doesn't call disconnect()
BreezSdkLiquid? _currentBreezClient;

/// Provider to explicitly disconnect the Breez client before invalidating
/// IMPORTANT: Call this BEFORE invalidating breezClientProvider
/// Returns true if disconnection was successful or no client was connected
final disconnectBreezClientProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final logger = ref.read(appLoggerProvider);

  if (_currentBreezClient == null) {
    logger.debug('BreezClient', 'No active client to disconnect');
    return true;
  }

  try {
    logger.info('BreezClient', 'Explicitly disconnecting Breez SDK...');
    await _currentBreezClient!.disconnect();
    _currentBreezClient = null;
    logger.info('BreezClient', '✅ Breez SDK disconnected successfully');

    // Wait for file handles to be released
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  } catch (e) {
    logger.warning(
      'BreezClient',
      'Error disconnecting Breez SDK: $e',
      error: e,
    );
    _currentBreezClient = null;
    // Even if disconnect fails, clear the reference
    return false;
  }
});

/// Provider to clean Breez data directory
/// Call this AFTER disconnecting and BEFORE importing a new wallet
final cleanBreezDataDirectoryProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final logger = ref.read(appLoggerProvider);

  try {
    final workingDir = await getApplicationDocumentsDirectory();
    final breezDir = Directory("${workingDir.path}/mooze");

    if (!await breezDir.exists()) {
      logger.debug(
        'BreezClient',
        'Breez directory does not exist, nothing to clean',
      );
      return true;
    }

    logger.info(
      'BreezClient',
      'Cleaning Breez data directory: ${breezDir.path}',
    );

    const maxAttempts = 5;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await breezDir.delete(recursive: true);
        logger.info('BreezClient', '✅ Breez directory deleted successfully');
        return true;
      } catch (e) {
        if (attempt < maxAttempts) {
          final delay = Duration(milliseconds: 500 * attempt);
          logger.debug(
            'BreezClient',
            'Delete attempt $attempt/$maxAttempts failed, retrying in ${delay.inMilliseconds}ms: $e',
          );
          await Future.delayed(delay);
        } else {
          logger.error(
            'BreezClient',
            'Failed to delete Breez directory after $maxAttempts attempts',
            error: e,
          );
        }
      }
    }

    return false;
  } catch (e) {
    logger.error('BreezClient', 'Error cleaning Breez directory', error: e);
    return false;
  }
});

/// Global flag to indicate wallet deletion is in progress
/// This prevents any new Breez connections during wallet deletion
bool _isWalletBeingDeleted = false;

/// Provider to set the wallet deletion flag
/// Call this BEFORE starting wallet deletion, and reset after deletion completes
final setWalletDeletionFlagProvider = Provider.family<void, bool>((
  ref,
  isDeleting,
) {
  _isWalletBeingDeleted = isDeleting;
  final logger = ref.read(appLoggerProvider);
  logger.debug('BreezClient', 'Wallet deletion flag set to: $isDeleting');
});

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

  // Check if wallet deletion is in progress - don't connect during deletion
  if (_isWalletBeingDeleted) {
    logger.warning(
      'BreezClient',
      'Wallet deletion in progress - skipping Breez connection',
    );
    return left('Wallet deletion in progress');
  }

  final config = await ref.read(configProvider.future);
  final mnemonicOption = await ref.watch(mnemonicProvider.future);
  final syncStream = ref.read(syncStreamProvider);

  return await mnemonicOption.fold(
    () async {
      logger.warning(
        'BreezClient',
        'Mnemonic not available - wallet may not be initialized or was deleted',
      );
      return left('Mnemonic not available');
    },
    (mnemonic) async {
      // Double-check deletion flag after mnemonic check (race condition protection)
      if (_isWalletBeingDeleted) {
        logger.warning(
          'BreezClient',
          'Wallet deletion started after mnemonic read - aborting connection',
        );
        return left('Wallet deletion in progress');
      }

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

          // Save global reference for cleanup
          _currentBreezClient = client;

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

              // Save global reference for cleanup
              _currentBreezClient = client;
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
) async {
  // Check mnemonic availability before starting sync
  final mnemonicOption = await ref.read(mnemonicProvider.future);
  if (mnemonicOption.isNone()) {
    logger.warning(
      'BreezClient',
      'Mnemonic not available - skipping background sync silently (wallet may have been deleted)',
    );
    // Emit completed (not error) so the boot orchestrator can proceed normally
    // and no error is shown to the user during wallet import flow
    syncStream.updateProgress(
      SyncProgress(
        datasource: 'Breez',
        status: SyncStatus.completed,
        timestamp: DateTime.now(),
      ),
    );
    return;
  }

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
        initialDelay: Duration(seconds: 4),
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

        // Detect errors caused by wallet deletion / SDK disconnection
        // These are expected during the wallet import flow and must NOT be shown to the user
        final isWalletDeletedError =
            errorMsg.contains('Mnemonic not available') ||
            errorMsg.contains('Wallet deletion in progress') ||
            errorMsg.contains('Breez client disconnected') ||
            errorMsg.contains('Breez SDK not started') ||
            errorMsg.contains('sync aborted') ||
            errorMsg.contains('notStarted') ||
            errorMsg.contains('SdkError.notStarted');

        if (isWalletDeletedError) {
          // Log as warning only - this is expected when the user deletes a wallet
          logger.warning(
            'BreezClient',
            'Background sync skipped (wallet deleted or SDK disconnected): $errorMsg',
          );
          // Emit completed so the boot orchestrator can finish normally
          // and the user can proceed to import a new seed without seeing errors
          syncStream.updateProgress(
            SyncProgress(
              datasource: 'Breez',
              status: SyncStatus.completed,
              timestamp: DateTime.now(),
            ),
          );
          syncEventController.emitCompleted('breez');
          return;
        }

        // Real sync error - log and propagate normally
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
    // Check if wallet deletion is in progress - abort sync
    if (_isWalletBeingDeleted) {
      logger.warning(
        'BreezClient',
        'Wallet deletion in progress - aborting sync attempt $attempt',
      );
      throw Exception('Wallet deletion in progress - sync aborted');
    }

    // Check if Breez client was disconnected (e.g. wallet deleted) - abort sync
    if (_currentBreezClient == null) {
      logger.warning(
        'BreezClient',
        'Breez client is null (disconnected) - aborting sync attempt $attempt',
      );
      throw Exception('Breez client disconnected - sync aborted');
    }

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

      // If SDK is not started (wallet deleted / disconnected), abort immediately
      if (lastError.contains('notStarted') ||
          lastError.contains('not_started') ||
          lastError.contains('SdkError.notStarted')) {
        logger.warning(
          'BreezClient',
          'SDK not started (client disconnected) - aborting sync immediately',
        );
        throw Exception(
          'Breez SDK not started - sync aborted (wallet may have been deleted)',
        );
      }

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
