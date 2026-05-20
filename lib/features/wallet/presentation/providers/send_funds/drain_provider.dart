import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import 'amount_provider.dart';
import 'clean_address_provider.dart';
import 'selected_asset_provider.dart';
import 'selected_network_provider.dart';

final drainTransactionProvider =
    FutureProvider<Either<WalletError, PartiallySignedTransaction>>((
      ref,
    ) async {
      final walletRepositoryResult = await ref.read(
        walletRepositoryProvider.future,
      );
      final destination = ref.watch(cleanAddressProvider);
      final asset = ref.watch(selectedAssetProvider);
      final blockchain = ref.watch(selectedNetworkProvider);

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
          return await repository
              .buildDrainStablecoinTransaction(destination, asset)
              .run();
        }
      });
    });

final isDrainAvailableProvider = Provider<bool>((ref) {
  final destination = ref.watch(cleanAddressProvider);
  return destination.isNotEmpty;
});

final isDrainTransactionProvider = Provider<bool>((ref) {
  if (!ref.watch(maxSendRequestedProvider)) return false;

  final destination = ref.watch(cleanAddressProvider);
  if (destination.isEmpty) return false;

  final amount = ref.watch(finalAmountProvider);
  if (amount <= 0) return false;

  return true;
});
