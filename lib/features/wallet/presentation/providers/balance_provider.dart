import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/presentation/controllers/balance_controller.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';

final balanceControllerProvider =
    FutureProvider.autoDispose<Either<WalletError, BalanceController>>((
      ref,
    ) async {
      final wallet = await ref.read(walletRepositoryProvider.future);
      return wallet.flatMap((w) => Either.right(BalanceController(w)));
    });

final allBalancesProvider = FutureProvider.autoDispose<Map<Asset, BigInt>>((
  ref,
) async {
  final logger = ref.read(appLoggerProvider);

  logger.info('AllBalancesProvider', 'Waiting for wallet repository...');

  // Watch the provider to stay in loading state while it's loading
  // This is KEY: the await here keeps THIS provider in loading state
  // until walletRepositoryProvider completes
  final walletRepository = await ref.watch(walletRepositoryProvider.future);

  logger.info(
    'AllBalancesProvider',
    'Wallet repository ready, fetching balances...',
  );

  return await walletRepository.fold(
    (error) async {
      // Capture stack trace for better debugging
      final stackTrace = StackTrace.current;
      logger.critical(
        'AllBalancesProvider',
        'Repository error - WalletError type: ${error.runtimeType}, Details: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
      );
      // Wait a bit before returning empty to give the repository time to initialize
      // This prevents showing 0.00 immediately during initialization
      await Future.delayed(const Duration(milliseconds: 500));
      return <Asset, BigInt>{};
    },
    (wallet) async {
      try {
        final balanceResult = await wallet.getBalance().run();

        return balanceResult.fold(
          (error) {
            final stackTrace = StackTrace.current;
            logger.critical(
              'AllBalancesProvider',
              'Balance fetch error - WalletError type: ${error.runtimeType}, Details: ${error.toString()}',
              error: error,
              stackTrace: stackTrace,
            );
            // Return empty map instead of throwing to prevent "N/A" in UI
            return <Asset, BigInt>{};
          },
          (fetchedBalances) {
            for (final entry in fetchedBalances.entries) {
              logger.debug(
                'AllBalancesProvider',
                '${entry.key.ticker}: ${entry.value}',
              );
            }

            logger.info(
              'AllBalancesProvider',
              'Loaded ${fetchedBalances.length} asset balance(s)',
            );

            return fetchedBalances;
          },
        );
      } catch (e, stackTrace) {
        logger.critical(
          'AllBalancesProvider',
          'Exception while fetching balances - Type: ${e.runtimeType}, Message: $e',
          error: e,
          stackTrace: stackTrace,
        );
        // Return empty map instead of throwing to prevent "N/A" in UI
        return <Asset, BigInt>{};
      }
    },
  );
});

/// Provider that returns the balance of a specific asset
final balanceProvider = FutureProvider.autoDispose
    .family<Either<WalletError, BigInt>, Asset>((ref, Asset asset) async {
      // Watch allBalancesProvider to ensure we wait for it to complete
      // This prevents returning zero while balances are still loading
      final allBalances = await ref.watch(allBalancesProvider.future);
      final balance = allBalances[asset] ?? BigInt.zero;

      return Either.right(balance);
    });
