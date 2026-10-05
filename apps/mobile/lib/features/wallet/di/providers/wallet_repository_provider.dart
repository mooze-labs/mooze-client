import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart' as v2;
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/domain/services/wallet_service.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/service_backed_wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/di/providers/swap_audit_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/database/database.dart' show AppDatabase;
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

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

  return _buildServiceBacked(ref, swapAudit, database, logger);
});

/// Builds [ServiceBackedWalletRepository] from the V2 services.
///
/// Waits for each service until it is operational or errored. An errored
/// service becomes `null`, so its methods return "not available".
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
  // the next microtask so the invalidation does not run during a build.
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
