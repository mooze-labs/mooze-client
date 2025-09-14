import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import 'address_provider.dart';
import 'selected_asset_provider.dart';
import 'selected_network_provider.dart';
import 'amount_provider.dart';

final drainTransactionProvider =
    FutureProvider<Either<WalletError, PartiallySignedTransaction>>((
      ref,
    ) async {
      final walletRepositoryResult = await ref.read(
        walletRepositoryProvider.future,
      );
      final destination = ref.watch(addressStateProvider);
      final asset = ref.watch(selectedAssetProvider);
      final blockchain = ref.watch(selectedNetworkProvider);

      // Validate destination
      if (destination.isEmpty) {
        return Either.left(
          WalletError(
            WalletErrorType.invalidAddress,
            "Endereço de destino é obrigatório",
          ),
        );
      }

      return walletRepositoryResult.fold((error) => Either.left(error), (
        repository,
      ) async {
        if (asset == Asset.btc) {
          switch (blockchain) {
            case Blockchain.bitcoin:
              return await repository
                  .buildDrainOnchainBitcoinTransaction(destination)
                  .run();
            case Blockchain.lightning:
              return await repository
                  .buildDrainLightningTransaction(destination)
                  .run();
            case Blockchain.liquid:
              return await repository
                  .buildDrainLiquidBitcoinTransaction(destination)
                  .run();
          }
        } else {
          // For stablecoins/assets, use the drain stablecoin method
          return await repository
              .buildDrainStablecoinTransaction(destination, asset)
              .run();
        }
      });
    });

final isDrainAvailableProvider = Provider<bool>((ref) {
  final destination = ref.watch(addressStateProvider);
  return destination.isNotEmpty;
});

final isDrainTransactionProvider = Provider<bool>((ref) {
  final destination = ref.watch(addressStateProvider);
  final currentAmount = ref.watch(finalAmountProvider);
  final maxAmountAsync = ref.watch(maxAvailableAmountProvider);

  print('[DEBUG isDrainTransactionProvider] destination: $destination');
  print('[DEBUG isDrainTransactionProvider] currentAmount: $currentAmount');

  if (destination.isEmpty) {
    print('[DEBUG isDrainTransactionProvider] No destination, returning false');
    return false;
  }

  return maxAmountAsync.when(
    data:
        (maxAmountResult) => maxAmountResult.fold(
          (error) {
            print(
              '[DEBUG isDrainTransactionProvider] Error getting max amount: $error',
            );
            return false;
          },
          (maxAmount) {
            final currentAmountBigInt = BigInt.from(currentAmount);
            final threshold = (maxAmount * BigInt.from(99)) ~/ BigInt.from(100);
            final isDrain =
                currentAmountBigInt >= threshold && maxAmount > BigInt.zero;

            print('[DEBUG isDrainTransactionProvider] maxAmount: $maxAmount');
            print(
              '[DEBUG isDrainTransactionProvider] threshold (99%): $threshold',
            );
            print(
              '[DEBUG isDrainTransactionProvider] currentAmountBigInt: $currentAmountBigInt',
            );
            print('[DEBUG isDrainTransactionProvider] isDrain: $isDrain');

            return isDrain;
          },
        ),
    loading: () {
      print(
        '[DEBUG isDrainTransactionProvider] Loading max amount, returning false',
      );
      return false;
    },
    error: (error, stackTrace) => false,
  );
});

final maxAvailableAmountProvider = FutureProvider<Either<WalletError, BigInt>>((
  ref,
) async {
  final walletRepositoryResult = await ref.read(
    walletRepositoryProvider.future,
  );
  final asset = ref.watch(selectedAssetProvider);

  return walletRepositoryResult.fold((error) => Either.left(error), (
    repository,
  ) async {
    final balanceResult = await repository.getBalance().run();

    return balanceResult.map((balance) {
      final assetBalance = balance[asset];
      return assetBalance ?? BigInt.zero;
    });
  });
});
