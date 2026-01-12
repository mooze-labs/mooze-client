import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
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

final allBalancesProvider = FutureProvider<Map<Asset, BigInt>>((ref) async {
  debugPrint(
    '[AllBalancesProvider] Waiting for wallet repository (includes Breez SDK)...',
  );

  final walletRepository = await ref.read(walletRepositoryProvider.future);

  debugPrint(
    '[AllBalancesProvider] Wallet repository ready, fetching balances...',
  );

  return walletRepository.fold(
    (error) {
      debugPrint('[AllBalancesProvider] ❌ Repository error: $error');
      return <Asset, BigInt>{};
    },
    (wallet) async {
      try {
        final balanceResult = await wallet.getBalance().run();

        return balanceResult.fold(
          (error) {
            return <Asset, BigInt>{};
          },
          (fetchedBalances) {
            for (final entry in fetchedBalances.entries) {
              debugPrint(
                '[AllBalancesProvider] ${entry.key.ticker}: ${entry.value}',
              );
            }

            return fetchedBalances;
          },
        );
      } catch (e) {
        debugPrint('[AllBalancesProvider] ❌ Exception: $e');
        return <Asset, BigInt>{};
      }
    },
  );
});

/// Provider that returns the balance of a specific asset
final balanceProvider =
    FutureProvider.family<Either<WalletError, BigInt>, Asset>((
      ref,
      Asset asset,
    ) async {
      final allBalances = await ref.watch(allBalancesProvider.future);
      final balance = allBalances[asset] ?? BigInt.zero;

      return Either.right(balance);
    });
