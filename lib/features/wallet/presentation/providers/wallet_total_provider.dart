import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';

const int _satsPerBtc = 100000000;

final totalWalletValueProvider =
    FutureProvider<Either<String, double>>((ref) async {
  final allAssets = ref.watch(allAssetsProvider);
  final allBalances = await ref.watch(allBalancesProvider.future);
  final quotes = ref.watch(priceQuotesProvider);

  double totalValue = 0.0;
  for (final asset in allAssets) {
    final balance = allBalances[asset] ?? BigInt.zero;
    if (balance <= BigInt.zero) continue;
    final price = quotes.priceFor(asset);
    if (price == null || price <= 0) continue;
    totalValue += (balance.toDouble() / _satsPerBtc) * price;
  }
  return Right(totalValue);
});

final totalWalletBitcoinProvider =
    FutureProvider<Either<String, double>>((ref) async {
  final allAssets = ref.watch(allAssetsProvider);
  final allBalances = await ref.watch(allBalancesProvider.future);
  final quotes = ref.watch(priceQuotesProvider);

  final btcPrice = quotes.priceFor(Asset.btc);
  if (btcPrice == null || btcPrice <= 0) {
    return const Right(0.0);
  }

  double totalBitcoin = 0.0;
  for (final asset in allAssets) {
    final balance = allBalances[asset] ?? BigInt.zero;
    if (balance <= BigInt.zero) continue;

    if (asset == Asset.btc || asset == Asset.lbtc) {
      totalBitcoin += balance.toDouble() / _satsPerBtc;
      continue;
    }

    final price = quotes.priceFor(asset);
    if (price == null || price <= 0) continue;
    final fiatValue = (balance.toDouble() / _satsPerBtc) * price;
    totalBitcoin += fiatValue / btcPrice;
  }
  return Right(totalBitcoin);
});

final totalWalletSatoshisProvider =
    Provider<AsyncValue<Either<String, BigInt>>>((ref) {
  final bitcoinValue = ref.watch(totalWalletBitcoinProvider);

  return bitcoinValue.when(
    data: (either) => AsyncValue.data(
      either.map((btcValue) {
        final satoshis = (btcValue * _satsPerBtc).round();
        return BigInt.from(satoshis);
      }),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final totalWalletVariationProvider =
    FutureProvider<Either<String, double>>((ref) async {
  final allAssets = ref.watch(allAssetsProvider);
  final allBalances = await ref.watch(allBalancesProvider.future);
  final quotes = ref.watch(priceQuotesProvider);

  double totalCurrentValue = 0.0;
  double totalVariation = 0.0;

  for (final asset in allAssets) {
    final balance = allBalances[asset] ?? BigInt.zero;
    if (balance <= BigInt.zero) continue;

    final price = quotes.priceFor(asset);
    if (price == null || price <= 0) continue;
    final assetValue = (balance.toDouble() / _satsPerBtc) * price;
    if (assetValue <= 0) continue;

    final variationResult =
        await ref.read(assetPercentageVariationProvider(asset).future);
    variationResult.fold((_) => null, (variation) {
      totalCurrentValue += assetValue;
      totalVariation += variation * assetValue;
    });
  }

  if (totalCurrentValue == 0) return const Right(0.0);
  return Right(totalVariation / totalCurrentValue);
});

