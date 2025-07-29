import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/prices/models.dart';

import 'package:mooze_mobile/shared/prices/providers.dart';

import 'selected_asset_provider.dart';

final assetQuoteProvider = FutureProvider.autoDispose<Either<String, Option<double>>>((
  ref,
) async {
  final selectedAsset = ref.read(selectedAssetProvider);
  final priceService = ref.read(priceServiceProvider);

  return await priceService
      .flatMap((service) => service.getCoinPrice(selectedAsset, optionalCurrency: Currency.brl))
      .run();
});
