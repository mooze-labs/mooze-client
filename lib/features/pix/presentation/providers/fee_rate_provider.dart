import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deposit_amount_provider.dart';
import 'referral_provider.dart';

const fixedFeeRateThreshold = 55.00;
const fixedFeeRate = 2.00;

final feeRateProvider = FutureProvider<double>((ref) async {
  double feeRate;
  final hasReferral = await ref.read(hasReferralProvider.future);
  final depositAmount = ref.read(depositAmountProvider);

  if (depositAmount < 500) {
    feeRate = 3.5;
  } else if (depositAmount < 5000) {
    feeRate = 3.25;
  } else {
    feeRate = 2.75;
  }

  if (hasReferral) feeRate -= 0.5;

  return feeRate;
});

final feeAmountProvider = FutureProvider<double>((ref) async {
  final depositAmount = ref.read(depositAmountProvider);
  if (depositAmount < fixedFeeRateThreshold) return fixedFeeRate;

  final feeRate = await ref.read(feeRateProvider.future);
  return depositAmount / 100 * feeRate;
});

final discountedFeesDepositProvider = FutureProvider<double>((ref) async {
  final depositAmount = ref.read(depositAmountProvider);
  if (depositAmount < fixedFeeRateThreshold) return depositAmount - fixedFeeRate;

  final feeAmount = await ref.read(feeAmountProvider.future);
  return depositAmount - feeAmount;
});