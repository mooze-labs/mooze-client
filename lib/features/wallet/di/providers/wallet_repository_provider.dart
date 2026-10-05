import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart' as v2;
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/domain/services/wallet_service.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/service_backed_wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/bitcoin.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/liquid.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/liquid_spend.dart';
import 'package:mooze_mobile/features/wallet/di/providers/swap_audit_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/database/database.dart' show AppDatabase;
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';

final walletRepositoryProvider = FutureProvider<
  Either<WalletError, WalletRepository>
>((ref) async {
  // Audit repo + database + logger are eagerly resolved — they have no
  // network dependencies and the wallet wrappers below pull them in via
  // constructor. Read (not watch) keeps wallet recreation from cycling
  // when the audit repo identity changes (it shouldn't).
  final swapAudit = ref.read(swapAuditRepositoryProvider);
  final database = ref.read(appDatabaseProvider);
  final logger = ref.read(appLoggerProvider);

  // mooze-core: the Core* services hold no LWK/BDK handles, so the legacy
  // datasource bridges below cannot work. Build the repository from the
  // V2 service interfaces instead.
  if (v2.useMoozeCore) {
    return _buildServiceBacked(ref, swapAudit, database, logger);
  }

  // Try to get each datasource independently - don't fail if one fails
  LiquidWallet? liquidWallet;
  LiquidSpendWallet? liquidSpend;
  BitcoinWallet? bitcoinWallet;

  // Try Liquid (LWK): balances, history, and every Liquid send/receive
  try {
    final liquidDatasource = await ref.watch(liquidDataSourceProvider.future);
    liquidDatasource.fold(
      (err) {
        logger.error(
          'walletRepositoryProvider(legacy)',
          'liquid-bridge returned Left: $err',
        );
        if (kDebugMode) {
          debugPrint('[WalletRepository] Liquid failed: $err');
        }
      },
      (l) {
        liquidWallet = LiquidWallet(l);
        liquidSpend = LiquidSpendWallet(ref.read(v2.liquidWalletServiceProvider));
        if (kDebugMode) {
          debugPrint('[WalletRepository] Liquid initialized successfully');
        }
      },
    );
  } catch (e, st) {
    logger.error(
      'walletRepositoryProvider(legacy)',
      'liquid-bridge threw exception: $e',
      error: e,
      stackTrace: st,
    );
    if (kDebugMode) {
      debugPrint('[WalletRepository] Liquid exception: $e');
    }
  }

  // Try BDK
  try {
    final bdkDatasource = await ref.watch(bdkDatasourceProvider.future);
    bdkDatasource.fold(
      (err) {
        logger.error(
          'walletRepositoryProvider(legacy)',
          'bdk-bridge returned Left: $err',
        );
        if (kDebugMode) {
          debugPrint('[WalletRepository] BDK failed: $err');
        }
      },
      (b) {
        bitcoinWallet = BitcoinWallet(b, database: database, logger: logger);
        if (kDebugMode) {
          debugPrint('[WalletRepository] BDK initialized successfully');
        }
      },
    );
  } catch (e, st) {
    logger.error(
      'walletRepositoryProvider(legacy)',
      'bdk-bridge threw exception: $e',
      error: e,
      stackTrace: st,
    );
    if (kDebugMode) {
      debugPrint('[WalletRepository] BDK exception: $e');
    }
  }

  // Check if we have at least one datasource working
  if (liquidWallet == null && bitcoinWallet == null) {
    return Either.left(
      WalletError(
        WalletErrorType.sdkError,
        'No wallet datasource available. Please check your connection.',
      ),
    );
  }

  // Create repository with available datasources
  // The repository will handle null datasources gracefully
  final repo = WalletRepositoryImpl(
    liquidSpend,
    bitcoinWallet,
    liquidWallet,
    swapAudit: swapAudit,
  );

  if (kDebugMode) {
    debugPrint('[WalletRepository] Repository created with:');
    debugPrint('  - Liquid: ${liquidWallet != null ? "✓" : "✗"}');
    debugPrint('  - BDK: ${bitcoinWallet != null ? "✓" : "✗"}');
  }

  // Persisted log so a failing receive can be traced from the log export
  // without needing kDebugMode. Names every resolved datasource and ties
  // them back to the V2-owned SDK instances (the legacy adapters are
  // bridges around V2 service clients — see the *_BRIDGE comments in
  // shared/infra/*/providers/*.dart).
  logger.info(
    'walletRepositoryProvider(legacy)',
    'resolved repoHash=${identityHashCode(repo)} '
        'liquid=${liquidWallet != null} '
        'bdk=${bitcoinWallet != null} '
        'note=all-datasources-are-v2-bridges',
  );

  return Either.right(repo);
});

/// Builds [ServiceBackedWalletRepository] from the V2 services. Used when
/// [v2.useMoozeCore] is true.
///
/// Waits for each service the way the legacy datasource bridges do: until
/// it is operational or errored. An errored service becomes `null`, so its
/// methods return "not available", as a failed datasource did before.
Future<Either<WalletError, WalletRepository>> _buildServiceBacked(
  Ref ref,
  SwapAuditRepository swapAudit,
  AppDatabase database,
  AppLoggerService logger,
) async {
  final liquidService = ref.read(v2.liquidWalletServiceProvider);
  final bitcoinService = ref.read(v2.bitcoinWalletServiceProvider);

  final ready = await Future.wait([
    _awaitOperational(liquidService),
    _awaitOperational(bitcoinService),
  ]);
  final liquidOk = ready[0];
  final bitcoinOk = ready[1];

  // A service that was not available at build time and connects later
  // re-resolves this provider, so the repository picks it up. Deferred to
  // the next microtask for the same reason as the datasource bridges.
  void watchRecovery(WalletService service, bool wasOk) {
    if (wasOk) return;
    final sub = service.state.listen((s) {
      if (s.isOperational) {
        Future.microtask(() {
          try {
            ref.invalidateSelf();
          } catch (_) {}
        });
      }
    });
    ref.onDispose(sub.cancel);
  }

  watchRecovery(liquidService, liquidOk);
  watchRecovery(bitcoinService, bitcoinOk);

  if (!liquidOk && !bitcoinOk) {
    logger.error(
      'walletRepositoryProvider(core)',
      'no V2 wallet service reached the operational state',
    );
    return Either.left(
      const WalletError(
        WalletErrorType.sdkError,
        'No wallet datasource available. Please check your connection.',
      ),
    );
  }

  final repo = ServiceBackedWalletRepository(
    liquid: liquidOk ? liquidService : null,
    bitcoin: bitcoinOk ? bitcoinService : null,
    swapAudit: swapAudit,
    database: database,
    logger: logger,
  );

  logger.info(
    'walletRepositoryProvider(core)',
    'resolved repoHash=${identityHashCode(repo)} '
        'liquid=$liquidOk bitcoin=$bitcoinOk note=service-backed',
  );

  return Either.right(repo);
}

/// True when [service] is operational, false when it errors or its state
/// stream closes first.
Future<bool> _awaitOperational(WalletService service) async {
  final current = service.currentState;
  if (current.isOperational) return true;
  if (current.lifecycle == ServiceLifecycle.errored) return false;
  await for (final s in service.state) {
    if (s.lifecycle == ServiceLifecycle.errored) return false;
    if (s.isOperational) return true;
  }
  return false;
}
