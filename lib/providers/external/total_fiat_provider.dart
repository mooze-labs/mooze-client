import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'price_provider.dart';
import 'package:mooze_mobile/providers/multichain/multichain_asset_provider.dart';

final totalFiatProvider = Provider<double>((ref) {
  // Watch the list of owned assets
  final assetsAsync = ref.watch(ownedMultiChainAssetsProvider);

  // Handle loading or error states
  if (assetsAsync.isLoading || assetsAsync.hasError) {
    return 0.0; // Return 0.0 while loading or if there’s an error
  }

  final assets = assetsAsync.value!; // Get the list of assets
  double totalFiat = 0.0;

  // Iterate over each asset
  for (var asset in assets) {
    if (asset.coingeckoId != null) {
      // Watch the fiat price for this asset
      final fiatPriceAsync = ref.watch(cryptoPriceProvider(asset.coingeckoId!));

      // Skip this asset if the price is loading or has an error
      if (fiatPriceAsync.isLoading || fiatPriceAsync.hasError) {
        continue;
      }

      final fiatPrice = fiatPriceAsync.value!; // Get the fiat price
      // Calculate fiat value: (amount / 10^precision) * fiatPrice
      final assetValue = (asset.amount / pow(10, asset.precision)) * fiatPrice;
      totalFiat += assetValue;
    }
  }

  return totalFiat;
});
