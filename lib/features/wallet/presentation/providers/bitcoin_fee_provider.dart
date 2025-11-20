import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/services/bitcoin_fee_service.dart';

final bitcoinFeeServiceProvider = Provider<BitcoinFeeService>((ref) {
  return BitcoinFeeService();
});

final bitcoinFeeEstimateProvider =
    FutureProvider.autoDispose<BitcoinFeeEstimate?>((ref) async {
      final service = ref.watch(bitcoinFeeServiceProvider);
      return await service.fetchFeeEstimate();
    });
