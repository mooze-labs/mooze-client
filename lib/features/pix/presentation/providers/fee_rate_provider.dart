import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deposit_amount_provider.dart';
import 'referral_provider.dart';

const fixedFeeRateThreshold = 55.00;
const fixedFeeRate = 2.00;

// Family provider that takes deposit amount as parameter
final feeRateProvider = FutureProvider.autoDispose.family<double, double>((
  ref,
  depositAmount,
) async {
  double feeRate;
  final hasReferral = await ref.read(hasReferralProvider.future);

  if (depositAmount < 500) {
    feeRate = 3.5;
  } else if (depositAmount < 5000) {
    feeRate = 3.25;
  } else {
    feeRate = 2.75;
  }

  if (hasReferral) feeRate *= 0.85;

  return feeRate;
});

// Family provider that takes deposit amount as parameter
final feeAmountProvider = FutureProvider.autoDispose.family<double, double>((
  ref,
  depositAmount,
) async {
  if (depositAmount < fixedFeeRateThreshold) return fixedFeeRate;

  final feeRate = await ref.read(feeRateProvider(depositAmount).future);
  return depositAmount / 100 * feeRate;
});

// Family provider that takes deposit amount as parameter
final discountedFeesDepositProvider = FutureProvider.autoDispose
    .family<double, double>((ref, depositAmount) async {
      if (depositAmount < fixedFeeRateThreshold)
        return depositAmount - fixedFeeRate;

      final feeAmount = await ref.read(feeAmountProvider(depositAmount).future);
      return depositAmount - feeAmount;
    });

// Legacy providers for backward compatibility - use selected deposit amount
final legacyFeeRateProvider = FutureProvider<double>((ref) async {
  final depositAmount = ref.read(depositAmountProvider);
  return ref.read(feeRateProvider(depositAmount).future);
});

final legacyFeeAmountProvider = FutureProvider<double>((ref) async {
  final depositAmount = ref.read(depositAmountProvider);
  return ref.read(feeAmountProvider(depositAmount).future);
});

final legacyDiscountedFeesDepositProvider = FutureProvider<double>((ref) async {
  final depositAmount = ref.read(depositAmountProvider);
  return ref.read(discountedFeesDepositProvider(depositAmount).future);
});
