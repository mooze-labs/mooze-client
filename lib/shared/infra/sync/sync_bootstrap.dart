import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../lwk/providers/datasource_provider.dart';
import 'sync_service_provider.dart';
import '../bdk/providers/datasource_provider.dart';
import 'wallet_data_manager.dart';
import 'sync_config.dart';
import '../../key_management/providers/mnemonic_provider.dart';
import '../../key_management/providers/has_pin_provider.dart';

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

  bool _hasInitialized = false;
  bool _liquidReady = false;
  bool _bdkReady = false;

  void _tryInitializeWallet() {
    if (!_hasInitialized && _liquidReady && _bdkReady) {
      WalletSyncLogger.info(
        "[WalletSyncBootstrapProvider] Ambos datasources prontos (Liquid: $_liquidReady, BDK: $_bdkReady), inicializando wallet",
      );
      _hasInitialized = true;
      ref.read(walletDataManagerProvider.notifier).initializeWallet();
    } else if (!_hasInitialized) {
      WalletSyncLogger.debug(
        "[WalletSyncBootstrapProvider] Aguardando datasources (Liquid: $_liquidReady, BDK: $_bdkReady)",
      );
    }
  }

  // Initialize the wallet data manager listener
  ref.listen(walletDataManagerProvider, (prev, next) {
    if (prev?.state != next.state) {
      debugPrint(
        "[WalletSyncBootstrapProvider] Wallet data state changed: ${prev?.state} → ${next.state}",
      );
    }
  });

  ref.listen<AsyncValue<Option<String>>>(mnemonicProvider, (previous, next) {
    next.whenData((mnemonicOption) async {
      final hasMnemonic = mnemonicOption.isSome();

      if (hasMnemonic) {
        try {
          final hasPin = await ref.read(hasPinProvider.future);

          if (!hasPin) {
            WalletSyncLogger.info(
              "[WalletSyncBootstrapProvider] Mnemonic disponível mas PIN não configurado, aguardando setup completo...",
            );
            _hasInitialized = false;
            _liquidReady = false;
            _bdkReady = false;
            return;
          }

          WalletSyncLogger.info(
            "[WalletSyncBootstrapProvider] Mnemonic e PIN disponíveis, iniciando datasources",
          );

          ref.read(liquidDataSourceProvider);
          ref.read(bdkDatasourceProvider);
        } catch (e) {
          WalletSyncLogger.error(
            "[WalletSyncBootstrapProvider] Erro ao verificar PIN: $e",
          );
          _hasInitialized = false;
          _liquidReady = false;
          _bdkReady = false;
        }
      } else {
        WalletSyncLogger.info(
          "[WalletSyncBootstrapProvider] Mnemonic não disponível, aguardando...",
        );
        _hasInitialized = false;
        _liquidReady = false;
        _bdkReady = false;
      }
    });
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
      data: (either) async {
        final mnemonicAsync = ref.read(mnemonicProvider);
        final hasMnemonic = mnemonicAsync.value?.isSome() ?? false;

        if (!hasMnemonic) {
          debugPrint(
            "[WalletSyncBootstrapProvider] Liquid datasource pronto mas sem mnemonic, ignorando",
          );
          _liquidReady = false;
          return;
        }

        try {
          final hasPin = await ref.read(hasPinProvider.future);
          if (!hasPin) {
            debugPrint(
              "[WalletSyncBootstrapProvider] Liquid datasource pronto mas sem PIN, ignorando",
            );
            _liquidReady = false;
            return;
          }
        } catch (e) {
          debugPrint(
            "[WalletSyncBootstrapProvider] Erro ao verificar PIN para Liquid: $e",
          );
          _liquidReady = false;
          return;
        }

        either.match(
          (error) {
            // Extract specific details from LwkError
            final errorDetails = _extractErrorDetails(error);
            debugPrint("Failed to start Liquid sync: $errorDetails");

            // Notify WalletDataManager about the failure with details
            ref
                .read(walletDataManagerProvider.notifier)
                .notifyLiquidSyncFailed(errorDetails);

            _liquidReady = false;
          },
          (datasource) {
            debugPrint("Liquid datasource ready, starting sync");
            // Notify datasource recovery
            ref
                .read(walletDataManagerProvider.notifier)
                .notifyDataSourceRecovered('liquid');

            _liquidReady = true;
            _tryInitializeWallet();

            ref.read(
              liquidSyncEffectProvider,
            ); // Keep the original sync as well
          },
        );
      },
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
      data: (either) async {
        final mnemonicAsync = ref.read(mnemonicProvider);
        final hasMnemonic = mnemonicAsync.value?.isSome() ?? false;

        if (!hasMnemonic) {
          debugPrint(
            "[WalletSyncBootstrapProvider] BDK datasource pronto mas sem mnemonic, ignorando",
          );
          _bdkReady = false;
          return;
        }

        try {
          final hasPin = await ref.read(hasPinProvider.future);
          if (!hasPin) {
            debugPrint(
              "[WalletSyncBootstrapProvider] BDK datasource pronto mas sem PIN, ignorando",
            );
            _bdkReady = false;
            return;
          }
        } catch (e) {
          debugPrint(
            "[WalletSyncBootstrapProvider] Erro ao verificar PIN para BDK: $e",
          );
          _bdkReady = false;
          return;
        }

        either.match(
          (error) {
            // Extract specific error details
            final errorDetails = _extractErrorDetails(error);
            debugPrint("Failed to start BDK sync: $errorDetails");

            // Notify WalletDataManager about the failure with details
            ref
                .read(walletDataManagerProvider.notifier)
                .notifyBdkSyncFailed(errorDetails);

            _bdkReady = false;
          },
          (datasource) {
            debugPrint("BDK datasource ready, starting sync");
            // Notify datasource recovery
            ref
                .read(walletDataManagerProvider.notifier)
                .notifyDataSourceRecovered('bdk');

            _bdkReady = true;
            _tryInitializeWallet();

            ref.read(bdkSyncEffectProvider);
          },
        );
      },
    );
  });
});
