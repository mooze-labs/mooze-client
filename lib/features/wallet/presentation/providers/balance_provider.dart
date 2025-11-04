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

final _allBalancesProvider = FutureProvider<Map<Asset, BigInt>>((ref) async {
  final walletRepository = await ref.read(walletRepositoryProvider.future);

  return walletRepository.fold(
    (error) {
      return <Asset, BigInt>{};
    },
    (wallet) async {
      Map<Asset, BigInt> balances = {};
      int attempts = 0;
      const maxAttempts = 10;
      const delayBetweenAttempts = Duration(milliseconds: 1500);

      while (attempts < maxAttempts) {
        attempts++;

        final balanceResult = await wallet.getBalance().run();

        balances = balanceResult.fold(
          (error) {
            return <Asset, BigInt>{};
          },
          (fetchedBalances) {
            return fetchedBalances;
          },
        );

        final hasNonZeroBalance = balances.values.any((b) => b > BigInt.zero);
        final totalBalance = balances.values.fold(
          BigInt.zero,
          (sum, b) => sum + b,
        );

        if (hasNonZeroBalance) {
          break;
        }

        if (attempts >= maxAttempts) {
          break;
        }

        await Future.delayed(delayBetweenAttempts);
      }

      return balances;
    },
  );
});

final balanceProvider =
    FutureProvider.family<Either<WalletError, BigInt>, Asset>((
      ref,
      Asset asset,
    ) async {
      final allBalances = await ref.watch(_allBalancesProvider.future);

      final balance = allBalances[asset] ?? BigInt.zero;

      return Either.right(balance);
    });
