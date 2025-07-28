import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deposit_amount_provider.dart';
import 'referral_provider.dart';

final feeProvider = FutureProvider.autoDispose<double>((ref) async {
  final hasReferral = await ref.read(hasReferralProvider.future);
  final depositAmount = ref.read(depositAmountProvider);

  if (depositAmount < 55) return 2.00;

  double feeRate;

  if (depositAmount < 500) {
    feeRate = 3.5;
  } else if (depositAmount < 5000) {
    feeRate = 3.25;
  } else {
    feeRate = 2.75;
  }

  if (hasReferral) feeRate -= 0.5;

  return depositAmount / 100 * feeRate;
});
