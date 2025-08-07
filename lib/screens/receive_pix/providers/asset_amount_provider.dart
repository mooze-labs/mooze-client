import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import '../providers/fee_rate_provider.dart';
import '../providers/pix_input_provider.dart';

part 'asset_amount_provider.g.dart';

@riverpod
class AssetAmount extends _$AssetAmount {
  @override
  Future<double> build() async {
    final pixInput = ref.watch(pixInputProvider);
    final fiatPrices = await ref.watch(fiatPricesProvider.future);
    final feeRate = await ref.watch(feeRateProvider.future);

    double fiatPrice = fiatPrices[pixInput.asset.fiatPriceId]!;
    if (pixInput.asset.id == "lbtc") {
      fiatPrice = fiatPrice * 1.02;
    }

    if (pixInput.amountInCents <= 0) {
      return 0.0;
    }

    if (pixInput.amountInCents < 55 * 100) {
      final fiatPrice = fiatPrices[pixInput.asset.fiatPriceId]!;
      final assetAmount = (pixInput.amountInCents - 200) / 100 / fiatPrice;
      return assetAmount;
    }

    final assetAmount = (pixInput.amountInCents - 100) / 100 / fiatPrice;
    final feeCollected =
        ((pixInput.amountInCents - 100) / 100) * feeRate / 100 / fiatPrice;
    final assetAmountAfterFees = assetAmount - feeCollected;

    if (kDebugMode) {
      print("pixInput.amountInCents: ${pixInput.amountInCents}");
      print("fiatPrice: $fiatPrice");
      print("assetAmount: $assetAmount");
      print("feeCollected: $feeCollected");
      print("assetAmountAfterFees: $assetAmountAfterFees");
    }

    return assetAmountAfterFees;
  }
}
