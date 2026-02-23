import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/bitcoin.dart';

import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/breez.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/liquid.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';

final walletRepositoryProvider = FutureProvider<
  Either<WalletError, WalletRepository>
>((ref) async {
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
        if (kDebugMode) {
          debugPrint('[WalletRepository] Breez failed: $err');
        }
      },
      (b) {
        breezWallet = BreezWallet(b);
        if (kDebugMode) {
          debugPrint('[WalletRepository] Breez initialized successfully');
        }
      },
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WalletRepository] Breez exception: $e');
    }
  }

  // Try Liquid (LWK) - should work independently of Breez
  try {
    final liquidDatasource = await ref.watch(liquidDataSourceProvider.future);
    liquidDatasource.fold(
      (err) {
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
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WalletRepository] Liquid exception: $e');
    }
  }

  // Try BDK
  try {
    final bdkDatasource = await ref.watch(bdkDatasourceProvider.future);
    bdkDatasource.fold(
      (err) {
        if (kDebugMode) {
          debugPrint('[WalletRepository] BDK failed: $err');
        }
      },
      (b) {
        bitcoinWallet = BitcoinWallet(b);
        if (kDebugMode) {
          debugPrint('[WalletRepository] BDK initialized successfully');
        }
      },
    );
  } catch (e) {
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
  final repo = WalletRepositoryImpl(breezWallet, bitcoinWallet, liquidWallet);

  if (kDebugMode) {
    debugPrint('[WalletRepository] Repository created with:');
    debugPrint('  - Breez: ${breezWallet != null ? "✓" : "✗"}');
    debugPrint('  - Liquid: ${liquidWallet != null ? "✓" : "✗"}');
    debugPrint('  - BDK: ${bitcoinWallet != null ? "✓" : "✗"}');
  }

  return Either.right(repo);
});
