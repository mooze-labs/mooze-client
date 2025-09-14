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
  int assetCount = 0;
  print(
    'DEBUG: Calculando valor total da carteira para ${allAssets.length} ativos',
  );

  try {
    for (final asset in allAssets) {
      final balanceResult = await ref.read(balanceProvider(asset).future);

      final hasBalance = balanceResult.fold(
        (error) => false,
        (balance) => balance > BigInt.zero,
      );

      if (!hasBalance) {
        print('DEBUG: Ativo ${asset.name} tem saldo zero, pulando');
        continue;
      }

      final priceResult = await ref.read(fiatPriceProvider(asset).future);

      final assetValue = balanceResult.fold(
        (error) {
          print('DEBUG: Erro ao obter saldo do ${asset.name}: $error');
          return 0.0;
        },
        (balance) => priceResult.fold(
          (error) {
            print('DEBUG: Erro ao obter preço do ${asset.name}: $error');
            return 0.0;
          },
          (price) {
            if (price <= 0) {
              print('DEBUG: Preço do ${asset.name} é inválido: $price');
              return 0.0;
            }

            double balanceInMainUnit;
            balanceInMainUnit = balance.toDouble() / 100000000;
            if (asset == Asset.btc) {
              print(
                'DEBUG: Bitcoin - Saldo em satoshis: $balance, em BTC: $balanceInMainUnit',
              );
            } else {
              print('DEBUG: ${asset.name} - Saldo: $balanceInMainUnit');
            }

            final value = balanceInMainUnit * price;
            print(
              'DEBUG: ${asset.name} - Saldo: $balanceInMainUnit, Preço: $price, Valor: $value',
            );
            return value;
          },
        ),
      );

      totalValue += assetValue;
      if (assetValue > 0) {
        assetCount++;
      }
    }

    print('DEBUG: Valor total calculado: $totalValue de $assetCount ativos');
    return Either.right(totalValue);
  } catch (e) {
    print('DEBUG: Erro durante o cálculo: $e');
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
      final balanceResult = await ref.read(balanceProvider(asset).future);
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
