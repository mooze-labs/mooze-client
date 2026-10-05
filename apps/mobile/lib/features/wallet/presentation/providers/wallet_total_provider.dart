import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';

const int _satsPerBtc = 100000000;

// Synchronous providers: when priceQuotesProvider emits new prices, these
// recompute immediately using the last-known balance snapshot (valueOrNull)
// instead of awaiting an async future. This eliminates the AsyncLoading state
// during price updates, preventing the header shimmer and layout shifts.

final totalWalletValueProvider =
    Provider<AsyncValue<Either<String, double>>>((ref) {
  final allAssets = ref.watch(allAssetsProvider);
  final allBalancesAsync = ref.watch(allBalancesProvider);
  final quotes = ref.watch(priceQuotesProvider);

  final allBalances = allBalancesAsync.valueOrNull;
  if (allBalances == null) return const AsyncValue.loading();

  double totalValue = 0.0;
  for (final asset in allAssets) {
    final balance = allBalances[asset] ?? BigInt.zero;
    if (balance <= BigInt.zero) continue;
    final price = quotes.priceFor(asset);
    if (price == null || price <= 0) continue;
    totalValue += (balance.toDouble() / _satsPerBtc) * price;
  }
  return AsyncValue.data(Right(totalValue));
});

final totalWalletBitcoinProvider =
    Provider<AsyncValue<Either<String, double>>>((ref) {
  final allAssets = ref.watch(allAssetsProvider);
  final allBalancesAsync = ref.watch(allBalancesProvider);
  final quotes = ref.watch(priceQuotesProvider);

  final allBalances = allBalancesAsync.valueOrNull;
  if (allBalances == null) return const AsyncValue.loading();

  final btcPrice = quotes.priceFor(Asset.btc);
  if (btcPrice == null || btcPrice <= 0) {
    return const AsyncValue.data(Right(0.0));
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
  return AsyncValue.data(Right(totalBitcoin));
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

// Variation is kept as a synchronous Provider that watches the per-asset
// variation providers directly (instead of awaiting their futures), so price
// updates recompute instantly with the last-known variation values.
final totalWalletVariationProvider =
    Provider<AsyncValue<Either<String, double>>>((ref) {
  final allAssets = ref.watch(allAssetsProvider);
  final allBalancesAsync = ref.watch(allBalancesProvider);
  final quotes = ref.watch(priceQuotesProvider);

  final allBalances = allBalancesAsync.valueOrNull;
  if (allBalances == null) return const AsyncValue.loading();

  double totalCurrentValue = 0.0;
  double totalVariation = 0.0;

  for (final asset in allAssets) {
    final balance = allBalances[asset] ?? BigInt.zero;
    if (balance <= BigInt.zero) continue;

    final price = quotes.priceFor(asset);
    if (price == null || price <= 0) continue;
    final assetValue = (balance.toDouble() / _satsPerBtc) * price;
    if (assetValue <= 0) continue;

    final variationAsync = ref.watch(assetPercentageVariationProvider(asset));
    final variationResult = variationAsync.valueOrNull;
    if (variationResult == null) continue;

    variationResult.fold((_) => null, (variation) {
      totalCurrentValue += assetValue;
      totalVariation += variation * assetValue;
    });
  }

  if (totalCurrentValue == 0) return const AsyncValue.data(Right(0.0));
  return AsyncValue.data(Right(totalVariation / totalCurrentValue));
});
