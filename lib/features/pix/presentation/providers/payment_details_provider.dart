import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/domain/entities/payment_details.dart';
import 'package:mooze_mobile/features/pix/di/providers/address_generator_repository_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import 'deposit_amount_provider.dart';
import 'selected_asset_provider.dart';
import 'asset_quote_provider.dart';
import 'fee_rate_provider.dart';

final paymentDetailsProvider = FutureProvider<Either<String, PaymentDetails>>((ref) async {
  // Get synchronous values
  final depositAmount = ref.read(depositAmountProvider);
  final selectedAsset = ref.read(selectedAssetProvider);
  
  // Wait for all async providers
  final quoteResult = await ref.read(assetQuoteProvider.future);
  final feeAmount = await ref.read(feeAmountProvider.future);
  final addressGenResult = await ref.read(addressGeneratorRepositoryProvider.future);
  
  // Handle quote result
  final quoteEither = quoteResult.fold(
    (error) => left('Failed to get asset quote: $error'),
    (quoteOption) => quoteOption.fold(
      () => left('No quote available'),
      (quote) => right(quote),
    ),
  );
  
  if (quoteEither.isLeft()) {
    return left(quoteEither.getLeft().getOrElse(() => ''));
  }
  final quote = quoteEither.getRight().getOrElse(() => 0.0);
  
  // Generate address
  final addressEither = await addressGenResult.fold(
    (error) => Future.value(left('Failed to get address repository: $error')),
    (repository) async {
      final result = await repository.generateNewAddress().run();
      return result.fold(
        (error) => left('Failed to generate address: $error'),
        (addr) => right(addr),
      );
    },
  );
  
  if (addressEither.isLeft()) {
    return left(addressEither.getLeft().getOrElse(() => ''));
  }
  final address = addressEither.getRight().getOrElse(() => '');
  
  // Calculate asset amount based on deposit amount and quote
  final assetAmount = _calculateAssetAmount(depositAmount, quote, selectedAsset);
  
  final paymentDetails = PaymentDetails(
    depositAmount: depositAmount,
    quote: quote,
    assetAmount: assetAmount,
    fee: feeAmount,
    address: address,
  );
  
  return right(paymentDetails);
});

BigInt _calculateAssetAmount(double depositAmount, double quote, Asset asset) {
  // Calculate how much of the asset the user will receive
  // This depends on the asset precision and conversion logic
  final amountInAsset = depositAmount / quote;
  
  // Convert to the asset's base unit (e.g., satoshis for Bitcoin)
  // This is a simplified calculation - adjust based on your asset precision logic
  switch (asset) {
    case Asset.depix:
      // Assuming DEPIX has 8 decimal places like Bitcoin
      return BigInt.from((amountInAsset * 100000000).round());
    default:
      return BigInt.from((amountInAsset * 100000000).round());
  }
}