import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/services/hybrid_price_service.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';

class AssetCacheInfo {
  final Asset asset;
  final bool hasCache;
  final int? ageInMinutes;
  final double? lastPrice;
  final String currencySymbol;

  AssetCacheInfo({
    required this.asset,
    required this.hasCache,
    this.ageInMinutes,
    this.lastPrice,
    this.currencySymbol = 'R\$',
  });
}

final cacheInfoProvider = FutureProvider<List<AssetCacheInfo>>((ref) async {
  final mainAssets = [Asset.btc, Asset.usdt, Asset.depix];


  final currency = ref.watch(priceQuotesProvider).currency;
  final currencySymbol = switch (currency) {
    Currency.brl => 'R\$',
    Currency.usd => '\$',
  };

  final priceService = HybridPriceService(currency, PriceSource.coingecko);
  final List<AssetCacheInfo> cacheInfoList = [];

  for (final asset in mainAssets) {
    try {
      final hasCacheResult = await priceService.hasCachedPrice(asset).run();
      final hasCache = hasCacheResult.fold(
        (error) => false,
        (hasCache) => hasCache,
      );

      if (!hasCache) {
        cacheInfoList.add(AssetCacheInfo(
          asset: asset,
          hasCache: false,
          currencySymbol: currencySymbol,
        ));
        continue;
      }

      final ageResult = await priceService.getCacheAgeInMinutes(asset).run();
      final ageInMinutes = ageResult.fold(
        (error) => null,
        (ageOption) => ageOption.fold(() => null, (age) => age),
      );

      final priceResult = await priceService.getCoinPrice(asset).run();
      final lastPrice = priceResult.fold(
        (error) => null,
        (priceOption) => priceOption.fold(() => null, (price) => price),
      );

      cacheInfoList.add(
        AssetCacheInfo(
          asset: asset,
          hasCache: true,
          ageInMinutes: ageInMinutes,
          lastPrice: lastPrice,
          currencySymbol: currencySymbol,
        ),
      );
    } catch (e) {
      cacheInfoList.add(AssetCacheInfo(
        asset: asset,
        hasCache: false,
        currencySymbol: currencySymbol,
      ));
    }
  }

  return cacheInfoList;
});
