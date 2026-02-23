import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';

import '../boot/boot_orchestrator.dart';
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
  final logger = ref.read(appLoggerProvider);
  logger.info('WalletSyncBootstrap', 'Initializing wallet sync bootstrap...');

  // Automatic reset on hot reload (development)
  ref.onDispose(() {
    logger.debug('WalletSyncBootstrap', 'Disposing - resetting state');
  });

  bool hasInitialized = false;
  bool liquidReady = false;
  bool bdkReady = false;

  void tryInitializeWallet() {
    if (!hasInitialized && liquidReady && bdkReady) {
      logger.info(
        'WalletSyncBootstrap',
        'Both datasources ready (Liquid: $liquidReady, BDK: $bdkReady), initializing wallet',
      );
      hasInitialized = true;
      ref.read(walletDataManagerProvider.notifier).initializeWallet();
    } else if (!hasInitialized) {
      logger.debug(
        'WalletSyncBootstrap',
        'Waiting for datasources (Liquid: $liquidReady, BDK: $bdkReady)',
      );
    }
  }

  // Initialize the wallet data manager listener
  ref.listen(walletDataManagerProvider, (prev, next) {
    if (prev?.state != next.state) {
      logger.debug(
        'WalletSyncBootstrap',
        'Wallet data state changed: ${prev?.state} → ${next.state}',
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
            logger.warning(
              'WalletSyncBootstrap',
              'Mnemonic available but PIN not configured, waiting for complete setup...',
            );
            hasInitialized = false;
            liquidReady = false;
            bdkReady = false;
            return;
          }

          logger.info(
            'WalletSyncBootstrap',
            'Mnemonic and PIN available, starting datasources',
          );

          ref.read(liquidDataSourceProvider);
          ref.read(bdkDatasourceProvider);
        } catch (e) {
          WalletSyncLogger.error(
            "[WalletSyncBootstrapProvider] Erro ao verificar PIN: $e",
          );
          hasInitialized = false;
          liquidReady = false;
          bdkReady = false;
        }
      } else {
        WalletSyncLogger.info(
          "[WalletSyncBootstrapProvider] Mnemonic não disponível, aguardando...",
        );
        hasInitialized = false;
        liquidReady = false;
        bdkReady = false;
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
          liquidReady = false;
          return;
        }

        try {
          final hasPin = await ref.read(hasPinProvider.future);
          if (!hasPin) {
            debugPrint(
              "[WalletSyncBootstrapProvider] Liquid datasource pronto mas sem PIN, ignorando",
            );
            liquidReady = false;
            return;
          }
        } catch (e) {
          debugPrint(
            "[WalletSyncBootstrapProvider] Erro ao verificar PIN para Liquid: $e",
          );
          liquidReady = false;
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

            liquidReady = false;
          },
          (datasource) {
            debugPrint("Liquid datasource ready, starting sync");
            // Notify datasource recovery
            ref
                .read(walletDataManagerProvider.notifier)
                .notifyDataSourceRecovered('liquid');

            liquidReady = true;
            tryInitializeWallet();

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
          bdkReady = false;
          return;
        }

        try {
          final hasPin = await ref.read(hasPinProvider.future);
          if (!hasPin) {
            debugPrint(
              "[WalletSyncBootstrapProvider] BDK datasource pronto mas sem PIN, ignorando",
            );
            bdkReady = false;
            return;
          }
        } catch (e) {
          debugPrint(
            "[WalletSyncBootstrapProvider] Erro ao verificar PIN para BDK: $e",
          );
          bdkReady = false;
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

            bdkReady = false;
          },
          (datasource) {
            debugPrint("BDK datasource ready, starting sync");
            // Notify datasource recovery
            ref
                .read(walletDataManagerProvider.notifier)
                .notifyDataSourceRecovered('bdk');

            bdkReady = true;
            tryInitializeWallet();

            ref.read(bdkSyncEffectProvider);
          },
        );
      },
    );
  });
});

/// Alternative provider that uses the new BootOrchestrator
///
/// This provider can be used as a replacement for walletSyncBootstrapProvider
/// for a more organized initialization with better phase management.
final walletBootOrchestratorProvider = Provider<void>((ref) {
  WalletSyncLogger.info("[WalletBootOrchestratorProvider] Initializing");

  // Observe mnemonic changes to start boot
  ref.listen<AsyncValue<Option<String>>>(mnemonicProvider, (previous, next) {
    next.whenData((mnemonicOption) async {
      final hasMnemonic = mnemonicOption.isSome();

      if (hasMnemonic) {
        try {
          final hasPin = await ref.read(hasPinProvider.future);

          if (!hasPin) {
            WalletSyncLogger.info(
              "[WalletBootOrchestratorProvider] Mnemonic disponível mas PIN não configurado",
            );
            return;
          }

          // Inicia o boot via novo orquestrador
          final bootState = ref.read(bootOrchestratorProvider);
          if (!bootState.isBooting && !bootState.isCompleted) {
            WalletSyncLogger.info(
              "[WalletBootOrchestratorProvider] Iniciando boot via orquestrador",
            );
            ref.read(bootOrchestratorProvider.notifier).startBoot();
          }
        } catch (e) {
          WalletSyncLogger.error(
            "[WalletBootOrchestratorProvider] Erro ao verificar PIN: $e",
          );
        }
      }
    });
  });

  // Observe boot state
  ref.listen(bootOrchestratorProvider, (prev, next) {
    if (prev?.phase != next.phase) {
      WalletSyncLogger.debug(
        "[WalletBootOrchestratorProvider] Boot phase: ${prev?.phase} → ${next.phase}",
      );
    }

    // Boot completo - apenas log, não precisa chamar initializeWallet novamente
    // pois o BootOrchestrator já chamou durante a fase showingUI
    if (next.isCompleted && prev?.phase != BootPhase.completed) {
      WalletSyncLogger.info(
        "[WalletBootOrchestratorProvider] Boot completo! Todas as sincronizações finalizadas.",
      );
    }
  });

  ref.onDispose(() {
    WalletSyncLogger.debug("[WalletBootOrchestratorProvider] Disposing");
  });
});
