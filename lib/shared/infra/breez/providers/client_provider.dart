import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:fpdart/fpdart.dart';

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
  final config = await ref.read(configProvider.future);
  final mnemonicOption = await ref.watch(mnemonicProvider.future);

  return await mnemonicOption.fold(() async => left('Mnemonic not available'), (
    mnemonic,
  ) async {
    const maxRetries = 3;
    const initialDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final connectRequest = ConnectRequest(
          mnemonic: mnemonic,
          config: config,
        );

        debugPrint(
          '[BreezClientProvider] Connecting to Breez SDK... (attempt $attempt/$maxRetries)',
        );
        final client = await connect(req: connectRequest);
        debugPrint('[BreezClientProvider] ✅ Breez SDK connected');

        // IMPORTANT: Sync immediately after connecting
        // This ensures balances will be available when any provider fetches them
        debugPrint('[BreezClientProvider] Syncing Breez SDK...');
        await client.sync();
        debugPrint('[BreezClientProvider] ✅ Breez SDK synced');

        return right(client);
      } catch (e) {
        final errorMessage = e.toString();

        // Handle database migration error
        if (errorMessage.contains('rusqlite_migrate') ||
            errorMessage.contains('duplicate column name')) {
          try {
            final dbDir = Directory(config.workingDir);
            if (await dbDir.exists()) {
              await dbDir.delete(recursive: true);
            }

            final retryRequest = ConnectRequest(
              mnemonic: mnemonic,
              config: config,
            );
            debugPrint(
              '[BreezClientProvider] Reconnecting to Breez SDK after cleanup...',
            );
            final client = await connect(req: retryRequest);
            debugPrint('[BreezClientProvider] ✅ Breez SDK reconnected');

            // Sync after reconnection as well
            debugPrint('[BreezClientProvider] Syncing Breez SDK...');
            await client.sync();
            debugPrint('[BreezClientProvider] ✅ Breez SDK synced');

            return right(client);
          } catch (retryError) {
            debugPrint(
              '[BreezClientProvider] ❌ Failed to reconnect: $retryError',
            );
            return left(
              'Failed to connect to Breez SDK after database cleanup: ${retryError.toString()}',
            );
          }
        }

        // For temporary errors, retry with exponential backoff
        if (_isRetryableError(errorMessage) && attempt < maxRetries) {
          final delay = initialDelay * (1 << (attempt - 1)); // 2s, 4s, 8s
          debugPrint(
            '[BreezClientProvider] ⚠️ Temporary error: $errorMessage. Retrying in ${delay.inSeconds}s...',
          );
          await Future.delayed(delay);
          continue;
        }

        // Unrecoverable error or last attempt
        debugPrint('[BreezClientProvider] ❌ Failed to connect: $errorMessage');
        return left('Failed to connect to Breez SDK: $errorMessage');
      }
    }

    // Should not reach here, but for safety
    return left('Failed to connect to Breez SDK after $maxRetries attempts');
  });
});
