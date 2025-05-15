import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/screens/receive_pix/providers/referral_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/screens/receive_pix/providers/pix_input_provider.dart';

part 'fee_rate_provider.g.dart';

@riverpod
class FeeRate extends _$FeeRate {
  @override
  Future<double> build() async {
    final pixInput = ref.watch(pixInputProvider);
    return calculateNewFeeRate(pixInput.amountInCents);
  }

  Future<double> calculateNewFeeRate(int amountInCents) async {
    double amountInReais = amountInCents / 100.0;
    double baseFee;

    if (amountInReais >= 5000) {
      baseFee = 2.75;
    } else if (amountInReais >= 500 && amountInReais < 5000) {
      baseFee = 3.25;
    } else {
      baseFee = 3.5;
    }

    final hasReferral = await ref.read(referralCodeProviderProvider.future);
    if (hasReferral) {
      baseFee -= 0.5;
    }

    return baseFee;
  }
}
