import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/address_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_detection_provider.dart';

final detectedAmountProvider = Provider<AmountDetectionResult>((ref) {
  final address = ref.watch(addressStateProvider);

  if (address.isEmpty) {
    return const AmountDetectionResult();
  }

  return AmountDetectionService.detectAmount(address);
});

final hasPreDefinedAmountProvider = Provider<bool>((ref) {
  final detectedAmount = ref.watch(detectedAmountProvider);
  return detectedAmount.hasAmount;
});
