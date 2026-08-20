import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/bitcoin.dart';

import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/breez.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/liquid.dart';
import 'package:mooze_mobile/features/wallet/di/providers/swap_audit_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
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

  // Try to get each datasource independently - don't fail if one fails
  BreezWallet? breezWallet;
  LiquidWallet? liquidWallet;
  BitcoinWallet? bitcoinWallet;

  // Try Breez
  try {
    // Use watch to ensure we get updated when Breez connects
    final breez = await ref.watch(breezClientProvider.future);
    breez.fold(
      (err) {
        // Surface the actual Left reason in the log export. Previously
        // this only printed in kDebugMode and never reached the
        // AppLogger, which is why the 2026-05-12 "breez=false" repro
        // could not be diagnosed from the log file — the reason was
        // invisible to anyone not attached to a Dart VM.
        logger.error(
          'walletRepositoryProvider(legacy)',
          'breez-bridge returned Left: $err',
        );
        if (kDebugMode) {
          debugPrint('[WalletRepository] Breez failed: $err');
        }
      },
      (b) {
        breezWallet = BreezWallet(b);
        logger.info(
          'walletRepositoryProvider(legacy)',
          'breez-bridge ok sdkHash=${identityHashCode(b)}',
        );
        if (kDebugMode) {
          debugPrint('[WalletRepository] Breez initialized successfully');
        }
      },
    );
  } catch (e, st) {
    logger.error(
      'walletRepositoryProvider(legacy)',
      'breez-bridge threw exception: $e',
      error: e,
      stackTrace: st,
    );
    if (kDebugMode) {
      debugPrint('[WalletRepository] Breez exception: $e');
    }
  }

  // Try Liquid (LWK) - should work independently of Breez
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
  if (breezWallet == null && liquidWallet == null && bitcoinWallet == null) {
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
    breezWallet,
    bitcoinWallet,
    liquidWallet,
    swapAudit: swapAudit,
  );

  if (kDebugMode) {
    debugPrint('[WalletRepository] Repository created with:');
    debugPrint('  - Breez: ${breezWallet != null ? "✓" : "✗"}');
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
        'breez=${breezWallet != null} '
        'liquid=${liquidWallet != null} '
        'bdk=${bitcoinWallet != null} '
        'note=all-datasources-are-v2-bridges',
  );

  return Either.right(repo);
});
