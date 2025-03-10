import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/external/coingecko_price_provider.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fiat_provider.g.dart';

@Riverpod()
String baseCurrency(Ref ref) {
  return "BRL";
}

@Riverpod()
Future<Map<String, double>> fiatPrices(Ref ref) async {
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final assets = AssetCatalog.all;

  final coingeckoAssets =
      assets
          .where((asset) => asset.fiatPriceId != null)
          .map((asset) => asset.fiatPriceId!)
          .toList();

  final CoingeckoAssetPairs coingeckoAssetPairs = CoingeckoAssetPairs(
    assets: coingeckoAssets,
    baseCurrency: baseCurrency,
  );

  final fiatPrices = await ref.read(
    coingeckoPriceProvider(coingeckoAssetPairs).future,
  );

  if (!fiatPrices.containsKey("tether")) {
    return fiatPrices;
  }

  final usdPrice = fiatPrices["tether"]!;
  final depixPrice = getDepixPrice(baseCurrency, usdPrice);

  fiatPrices["depix"] = depixPrice;

  return fiatPrices;
}

double getDepixPrice(String baseCurrency, double usdPrice) {
  if (baseCurrency == "BRL") return 1.0;

  return 1.0 / usdPrice;
}
