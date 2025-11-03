import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/presentation/controllers/balance_controller.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

final balanceControllerProvider =
    FutureProvider<Either<WalletError, BalanceController>>((ref) async {
      final wallet = await ref.read(walletRepositoryProvider.future);
      return wallet.flatMap((w) => Either.right(BalanceController(w)));
    });

final _allBalancesProvider = FutureProvider<Map<Asset, BigInt>>((ref) async {
  debugPrint(
    '[BalanceProvider] Fetching ALL balances directly from wallet...',
  );

  final walletRepository = await ref.read(walletRepositoryProvider.future);

  return walletRepository.fold(
    (error) {
      debugPrint('[BalanceProvider] Error getting wallet repository: $error');
      return <Asset, BigInt>{};
    },
    (wallet) async {
      Map<Asset, BigInt> balances = {};
      int attempts = 0;
      const maxAttempts = 10;
      const delayBetweenAttempts = Duration(
        milliseconds: 1500,
      );

      while (attempts < maxAttempts) {
        attempts++;
        debugPrint('[BalanceProvider] Attempt $attempts/$maxAttempts...');

        final balanceResult = await wallet.getBalance().run();

        balances = balanceResult.fold(
          (error) {
            debugPrint('[BalanceProvider] Error fetching balances: $error');
            return <Asset, BigInt>{};
          },
          (fetchedBalances) {
            debugPrint(
              '[BalanceProvider] 📦 Received ${fetchedBalances.length} assets from wallet',
            );
            return fetchedBalances;
          },
        );

        final hasNonZeroBalance = balances.values.any((b) => b > BigInt.zero);
        final totalBalance = balances.values.fold(
          BigInt.zero,
          (sum, b) => sum + b,
        );

        debugPrint(
          '[BalanceProvider] Total balance across all assets: $totalBalance',
        );

        if (hasNonZeroBalance) {
          debugPrint(
            '[BalanceProvider] Found non-zero balances after $attempts attempts!',
          );
          for (final entry in balances.entries) {
            debugPrint('[BalanceProvider]    ${entry.key}: ${entry.value}');
          }
          break;
        }

        if (attempts >= maxAttempts) {
          debugPrint(
            '[BalanceProvider] Max attempts reached, returning current balances (all zero)',
          );
          for (final entry in balances.entries) {
            debugPrint('[BalanceProvider]    ${entry.key}: ${entry.value}');
          }
          break;
        }

        debugPrint(
          '[BalanceProvider] All balances are zero, waiting ${delayBetweenAttempts.inMilliseconds}ms before retry...',
        );
        await Future.delayed(delayBetweenAttempts);
      }

      return balances;
    },
  );
});

final balanceProvider = FutureProvider.family<
  Either<WalletError, BigInt>,
  Asset
>((ref, Asset asset) async {
  debugPrint(
    '[BalanceProvider] Getting balance for $asset from cached data...',
  );

  final allBalances = await ref.watch(_allBalancesProvider.future);

  final balance = allBalances[asset] ?? BigInt.zero;
  debugPrint('[BalanceProvider] Balance for $asset: $balance');

  return Either.right(balance);
});
