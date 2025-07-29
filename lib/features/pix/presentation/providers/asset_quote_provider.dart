import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/prices/models.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import 'package:mooze_mobile/shared/prices/providers.dart';

import 'selected_asset_provider.dart';

final assetQuoteProvider = FutureProvider.autoDispose.family<Either<String, Option<double>>, Asset>((
  ref,
  asset,
) async {
  final priceService = ref.read(priceServiceProvider);

  return await priceService
      .flatMap((service) => service.getCoinPrice(asset, optionalCurrency: Currency.brl))
      .run();
});

// Legacy provider for backward compatibility - uses selected asset
final legacyAssetQuoteProvider = FutureProvider.autoDispose<Either<String, Option<double>>>((
  ref,
) async {
  final selectedAsset = ref.read(selectedAssetProvider);
  return ref.read(assetQuoteProvider(selectedAsset).future);
});
