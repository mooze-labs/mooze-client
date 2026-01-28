import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_info_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';

/// Model for values to receive for each asset
class AssetToReceive {
  final Asset asset;
  final int valueInSatoshis;
  final String formattedValue;
  final String formattedValueInFiat;
  final double valueInFiat;

  const AssetToReceive({
    required this.asset,
    required this.valueInSatoshis,
    required this.formattedValue,
    required this.formattedValueInFiat,
    required this.valueInFiat,
  });

  double get valueInReais => valueInSatoshis / 100000000.0;
}

/// Provider that returns the values to receive grouped by asset
final valuesToReceiveProvider = FutureProvider.autoDispose<
  Either<String, List<AssetToReceive>>
>((ref) async {
  final userInfo = await ref.watch(userInfoProvider.future);
  final currencyIcon = ref.watch(currencyControllerProvider.notifier).icon;

  return userInfo.fold((error) => Either.left(error), (user) async {
    try {
      final List<AssetToReceive> toReceiveList = [];

      for (final entry in user.valuesToReceive.entries) {
        final assetId = entry.key;
        final valueInSatoshis = entry.value;

        if (valueInSatoshis > 0) {
          final asset = _getAssetFromId(assetId);
          if (asset != null) {
            String formattedValue;
            String formattedValueInFiat;
            double valueInFiat;

            final assetAmount = valueInSatoshis / 100000000.0;
            final priceResult = await ref.read(fiatPriceProvider(asset).future);

            valueInFiat = priceResult.fold(
              (error) => 0.0,
              (price) => assetAmount * price,
            );

            if (asset == Asset.btc || asset == Asset.lbtc) {
              final formatter = NumberFormat('#,##0', 'pt_BR');
              final formattedSats = formatter.format(valueInSatoshis);
              formattedValue = '$formattedSats sats';
            } else {
              final formatter = NumberFormat('#,##0.00000000', 'pt_BR');
              final formattedAmount = formatter.format(assetAmount);
              formattedValue = '$formattedAmount ${asset.ticker}';
            }

            formattedValueInFiat =
                '$currencyIcon ${valueInFiat.toStringAsFixed(2)}';

            toReceiveList.add(
              AssetToReceive(
                asset: asset,
                valueInSatoshis: valueInSatoshis,
                formattedValue: formattedValue,
                formattedValueInFiat: formattedValueInFiat,
                valueInFiat: valueInFiat,
              ),
            );
          }
        }
      }

      // Sort by value (highest first)
      toReceiveList.sort(
        (a, b) => b.valueInSatoshis.compareTo(a.valueInSatoshis),
      );

      return Either.right(toReceiveList);
    } catch (e) {
      return Either.left('Erro ao processar valores a receber: $e');
    }
  });
});

/// Provider that returns the total value to receive across all assets in BRL
final totalValueToReceiveProvider = FutureProvider.autoDispose<double>((
  ref,
) async {
  final valuesToReceiveResult = await ref.watch(valuesToReceiveProvider.future);

  return valuesToReceiveResult.fold((error) => 0.0, (toReceiveList) {
    final total = toReceiveList.fold<double>(
      0.0,
      (sum, item) => sum + item.valueInFiat,
    );
    return total;
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
