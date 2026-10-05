import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart' show PixFeeDto;
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';

import 'deposit_amount_provider.dart';
import 'referral_provider.dart';

/// Upper bound of the fixed-fee tier, in BRL. The UI uses it to pick the
/// fee wording. The fee math runs in mooze-core (`pixFee`).
const fixedFeeRateThreshold = 55.00;

/// Fee breakdown from mooze-core for a deposit amount in BRL.
final pixFeeProvider = FutureProvider.autoDispose.family<PixFeeDto, double>((
  ref,
  depositAmount,
) async {
  final hasReferral = await ref.read(hasReferralProvider.future);
  return CoreSyncHelpers.instance.pixFee(
    amountBrl: depositAmount,
    hasReferral: hasReferral,
  );
});

/// Percent fee rate, after the referral discount.
final feeRateProvider = FutureProvider.autoDispose.family<double, double>((
  ref,
  depositAmount,
) async {
  final fee = await ref.read(pixFeeProvider(depositAmount).future);
  return fee.feeRatePercent;
});

/// Fee in BRL.
final feeAmountProvider = FutureProvider.autoDispose.family<double, double>((
  ref,
  depositAmount,
) async {
  final fee = await ref.read(pixFeeProvider(depositAmount).future);
  return fee.feeAmount;
});

/// BRL left after fees.
final discountedFeesDepositProvider = FutureProvider.autoDispose
    .family<double, double>((ref, depositAmount) async {
      final fee = await ref.read(pixFeeProvider(depositAmount).future);
      return fee.discountedAmount;
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
