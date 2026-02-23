import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'detected_amount_provider.dart';

final amountStateProvider = StateProvider<int>((ref) => 0);

final finalAmountProvider = Provider<int>((ref) {
  final detectedAmount = ref.watch(detectedAmountProvider);
  final manualAmount = ref.watch(amountStateProvider);

  if (detectedAmount.hasAmount) {
    return detectedAmount.amountInSats!;
  }

  return manualAmount;
});
