import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_info_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';

/// Model for values to receive for each asset
class AssetToReceive {
  final Asset asset;
  // Value in BRL cents, as returned by the API
  final int valueInCents;
  final String formattedValue;
  // Display value in the user's chosen currency
  final double displayValue;

  const AssetToReceive({
    required this.asset,
    required this.valueInCents,
    required this.formattedValue,
    required this.displayValue,
  });

  double get valueInReais => valueInCents / 100.0;
}

/// Provider that returns the values to receive grouped by asset
final valuesToReceiveProvider = FutureProvider.autoDispose<
  Either<String, List<AssetToReceive>>
>((ref) async {
  final userInfo = await ref.watch(userInfoProvider.future);
  final currency = ref.watch(currencyControllerProvider);
  final currencyIcon = ref.watch(currencyControllerProvider.notifier).icon;
  final formatter = NumberFormat('#,##0.00', 'pt_BR');

  double brlToUsdRate = 1.0;
  if (currency == Currency.usd) {
    final depixPriceResult = await ref.watch(
      fiatPriceProvider(Asset.depix).future,
    );
    depixPriceResult.fold((_) => null, (rate) {
      if (rate > 0) brlToUsdRate = rate;
    });
  }

  return userInfo.fold((error) => Either.left(error), (user) {
    try {
      final List<AssetToReceive> toReceiveList = [];

      for (final entry in user.valuesToReceive.entries) {
        final assetId = entry.key;
        final valueInCents = entry.value;

        if (valueInCents > 0) {
          final asset = _getAssetFromId(assetId);
          if (asset != null) {
            final valueInReais = valueInCents / 100.0;
            final displayValue = valueInReais * brlToUsdRate;
            final formattedValue =
                '$currencyIcon ${formatter.format(displayValue)}';

            toReceiveList.add(
              AssetToReceive(
                asset: asset,
                valueInCents: valueInCents,
                formattedValue: formattedValue,
                displayValue: displayValue,
              ),
            );
          }
        }
      }

      // Sort by value (highest first)
      toReceiveList.sort((a, b) => b.valueInCents.compareTo(a.valueInCents));

      return Either.right(toReceiveList);
    } catch (e) {
      return Either.left('Erro ao processar valores a receber: $e');
    }
  });
});

/// Provider that returns the total value to receive in the user's currency
final totalValueToReceiveProvider = FutureProvider.autoDispose<double>((
  ref,
) async {
  final valuesToReceiveResult = await ref.watch(valuesToReceiveProvider.future);

  return valuesToReceiveResult.fold((error) => 0.0, (toReceiveList) {
    return toReceiveList.fold<double>(
      0.0,
      (sum, item) => sum + item.displayValue,
    );
  });
});

/// Helper function to map asset ID to Asset enum
Asset? _getAssetFromId(String assetId) {
  switch (assetId) {
    // Liquid Bitcoin asset ID
    case '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d':
      return Asset.lbtc;
    // Depix asset ID (based on the example)
    case '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189':
      return Asset.depix;
    // Add other asset IDs as needed
    default:
      return null;
  }
}
