import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lwk/providers/datasource_provider.dart';
import 'sync_service_provider.dart';
import '../bdk/providers/datasource_provider.dart';
import 'wallet_data_manager.dart';
import 'sync_config.dart';

/// Extracts useful details from LwkError
String _extractErrorDetails(dynamic error) {
  if (error == null) return 'Unknown error';

  final errorString = error.toString();

  // If it's a generic "Instance of 'LwkError'" error, try to extract more information
  if (errorString.contains("Instance of 'LwkError'")) {
    try {
      // Try to access common error properties
      final errorType = error.runtimeType.toString();

      // Check if the error has a message or description
      if (error is Exception) {
        return 'LwkError: ${error.toString()}';
      }

      // If no further details can be extracted, return the type
      return 'LwkError ($errorType) - Check network connection and Liquid network status';
    } catch (e) {
      return 'LwkError - Network connection or Liquid sync failure';
    }
  }

  return errorString;
}

final walletSyncBootstrapProvider = Provider<void>((ref) {
  WalletSyncLogger.info("[WalletSyncBootstrapProvider] Initializing");

  // Automatic reset on hot reload (development)
  ref.onDispose(() {
    WalletSyncLogger.debug(
      "[WalletSyncBootstrapProvider] Disposing - resetting state",
    );
  });

  // Initialize the wallet data manager
  ref.listen(walletDataManagerProvider, (prev, next) {
    if (prev?.state != next.state) {
      debugPrint(
        "[WalletSyncBootstrapProvider] Wallet data state changed: ${prev?.state} → ${next.state}",
      );
    }
  });

  // Start Liquid sync when datasource is ready
  ref.listen(liquidDataSourceProvider, (prev, next) {
    // Detect provider state changes (important for hot reload)
    if (prev?.hasValue != next.hasValue ||
        (prev?.hasValue == true &&
            next.hasValue &&
            prev?.value != next.value)) {
      debugPrint(
        "[WalletSyncBootstrapProvider] Liquid datasource state changed",
      );
    }

    next.whenOrNull(
      data:
          (either) => either.match(
            (error) {
              // Extract specific details from LwkError
              final errorDetails = _extractErrorDetails(error);
              debugPrint("Failed to start Liquid sync: $errorDetails");

              // Notify WalletDataManager about the failure with details
              ref
                  .read(walletDataManagerProvider.notifier)
                  .notifyLiquidSyncFailed(errorDetails);
            },
            (datasource) {
              debugPrint("Liquid datasource ready, starting sync");
              // Notify datasource recovery
              ref
                  .read(walletDataManagerProvider.notifier)
                  .notifyDataSourceRecovered('liquid');
              // Try to initialize the wallet when datasource is ready
              ref.read(walletDataManagerProvider.notifier).initializeWallet();
              ref.read(
                liquidSyncEffectProvider,
              ); // Keep the original sync as well
            },
          ),
    );
  });

  // Start BDK sync when datasource is ready
  ref.listen(bdkDatasourceProvider, (prev, next) {
    // Detect provider state changes (important for hot reload)
    if (prev?.hasValue != next.hasValue ||
        (prev?.hasValue == true &&
            next.hasValue &&
            prev?.value != next.value)) {
      debugPrint("[WalletSyncBootstrapProvider] BDK datasource state changed");
    }

    next.whenOrNull(
      data:
          (either) => either.match(
            (error) {
              // Extract specific error details
              final errorDetails = _extractErrorDetails(error);
              debugPrint("Failed to start BDK sync: $errorDetails");

              // Notify WalletDataManager about the failure with details
              ref
                  .read(walletDataManagerProvider.notifier)
                  .notifyBdkSyncFailed(errorDetails);
            },
            (datasource) {
              debugPrint("BDK datasource ready, starting sync");
              // Notify datasource recovery
              ref
                  .read(walletDataManagerProvider.notifier)
                  .notifyDataSourceRecovered('bdk');
              ref.read(bdkSyncEffectProvider);
            },
          ),
    );
  });
});
