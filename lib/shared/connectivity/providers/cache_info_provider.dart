import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/services/hybrid_price_service.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';

class AssetCacheInfo {
  final Asset asset;
  final bool hasCache;
  final int? ageInMinutes;
  final double? lastPrice;

  AssetCacheInfo({
    required this.asset,
    required this.hasCache,
    this.ageInMinutes,
    this.lastPrice,
  });

  String get formattedAge {
    if (ageInMinutes == null) return 'Sem dados';

    if (ageInMinutes! < 60) {
      return '${ageInMinutes}min atrás';
    } else if (ageInMinutes! < 1440) {
      final hours = (ageInMinutes! / 60).round();
      return '${hours}h atrás';
    } else {
      final days = (ageInMinutes! / 1440).round();
      return '${days}d atrás';
    }
  }

  String get formattedPrice {
    if (lastPrice == null) return 'N/A';
    return 'R\$ ${lastPrice!.toStringAsFixed(2)}';
  }
}

final cacheInfoProvider = FutureProvider<List<AssetCacheInfo>>((ref) async {
  final mainAssets = [Asset.btc, Asset.usdt, Asset.depix];

  final priceService = HybridPriceService(Currency.brl, PriceSource.coingecko);
  final List<AssetCacheInfo> cacheInfoList = [];

  for (final asset in mainAssets) {
    try {
      final hasCacheResult = await priceService.hasCachedPrice(asset).run();
      final hasCache = hasCacheResult.fold(
        (error) => false,
        (hasCache) => hasCache,
      );

      if (!hasCache) {
        cacheInfoList.add(AssetCacheInfo(asset: asset, hasCache: false));
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
        ),
      );
    } catch (e) {
      cacheInfoList.add(AssetCacheInfo(asset: asset, hasCache: false));
    }
  }

  return cacheInfoList;
});
