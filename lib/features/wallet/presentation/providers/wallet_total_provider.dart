import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';

final totalWalletValueProvider = FutureProvider<Either<String, double>>((
  ref,
) async {
  final allAssets = ref.watch(allAssetsProvider);
  ref.watch(currencyControllerProvider);

  double totalValue = 0.0;

  try {
    for (final asset in allAssets) {
      final balanceAsync = ref.watch(balanceProvider(asset));

      final balanceResult = await balanceAsync.when(
        data: (data) async => data,
        loading: () async {
          return await ref.read(balanceProvider(asset).future);
        },
        error: (error, stack) async => throw error,
      );

      final hasBalance = balanceResult.fold(
        (error) => false,
        (balance) => balance > BigInt.zero,
      );

      if (!hasBalance) {
        continue;
      }

      final priceResult = await ref.read(fiatPriceProvider(asset).future);

      final assetValue = balanceResult.fold(
        (error) {
          return 0.0;
        },
        (balance) => priceResult.fold(
          (error) {
            return 0.0;
          },
          (price) {
            if (price <= 0) {
              return 0.0;
            }

            double balanceInMainUnit;
            balanceInMainUnit = balance.toDouble() / 100000000;
            if (asset == Asset.btc) {
            } else {
              // For other assets, you might want to adjust the conversion
              // depending on their decimal places. Here we assume 8 decimals.
            }

            final value = balanceInMainUnit * price;
            return value;
          },
        ),
      );

      totalValue += assetValue;
    }

    return Either.right(totalValue);
  } catch (e) {
    return Either.left('Erro ao calcular valor total: $e');
  }
});

final totalWalletBitcoinProvider = FutureProvider<Either<String, double>>((
  ref,
) async {
  final allAssets = ref.watch(allAssetsProvider);
  ref.watch(currencyControllerProvider);

  double totalBitcoin = 0.0;

  try {
    final btcPriceResult = await ref.read(fiatPriceProvider(Asset.btc).future);
    final btcPrice = btcPriceResult.fold((error) => 0.0, (price) => price);

    if (btcPrice == 0) {
      return Either.left("Não foi possível obter o preço do Bitcoin");
    }

    for (final asset in allAssets) {
      final balanceAsync = ref.watch(balanceProvider(asset));

      final balanceResult = await balanceAsync.when(
        data: (data) async => data,
        loading: () async {
          return await ref.read(balanceProvider(asset).future);
        },
        error: (error, stack) async => throw error,
      );

      final priceResult = await ref.read(fiatPriceProvider(asset).future);

      final hasBalance = balanceResult.fold(
        (error) => false,
        (balance) => balance > BigInt.zero,
      );

      if (!hasBalance) {
        continue;
      }

      final valueInBtc = balanceResult.fold(
        (error) => 0.0,
        (balance) => priceResult.fold((error) => 0.0, (price) {
          if (price == 0) return 0.0;

          if (asset == Asset.btc) {
            return balance.toDouble() / 100000000;
          } else {
            final balanceInMainUnit = balance.toDouble() / 100000000;
            final fiatValue = balanceInMainUnit * price;
            return fiatValue / btcPrice;
          }
        }),
      );

      totalBitcoin += valueInBtc;
    }

    return Either.right(totalBitcoin);
  } catch (e) {
    return Either.left('Erro ao calcular valor em Bitcoin: $e');
  }
});

final totalWalletSatoshisProvider =
    Provider<AsyncValue<Either<String, BigInt>>>((ref) {
      final bitcoinValue = ref.watch(totalWalletBitcoinProvider);

      return bitcoinValue.when(
        data:
            (either) => AsyncValue.data(
              either.map((btcValue) => BigInt.from(btcValue * 100000000)),
            ),
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });

final totalWalletVariationProvider = FutureProvider<Either<String, double>>((
  ref,
) async {
  final allAssets = ref.watch(allAssetsProvider);
  ref.watch(currencyControllerProvider);
  double totalCurrentValue = 0.0;
  double totalVariation = 0.0;
  int validAssets = 0;

  for (final asset in allAssets) {
    final variationResult = await ref.read(
      assetPercentageVariationProvider(asset).future,
    );

    final balanceResult = await ref.read(balanceProvider(asset).future);
    final priceResult = await ref.read(fiatPriceProvider(asset).future);

    final assetValue = balanceResult.fold(
      (error) => 0.0,
      (balance) => priceResult.fold((error) => 0.0, (price) {
        final balanceInMainUnit = balance.toDouble() / 100000000;

        return balanceInMainUnit * price;
      }),
    );

    if (assetValue > 0) {
      totalCurrentValue += assetValue;

      variationResult.fold((error) => null, (variation) {
        totalVariation += variation * assetValue;
        validAssets++;
      });
    }
  }

  if (totalCurrentValue == 0 || validAssets == 0) {
    return Either.right(0.0);
  }

  final weightedVariation = totalVariation / totalCurrentValue;

  return Either.right(weightedVariation);
});
