import 'package:flutter/foundation.dart';
import '../../domain/interfaces/fee_provider.dart';
import '../../domain/models/bitcoin_fee_estimate.dart';
import '../providers/blockstream_fee_provider.dart';
import '../providers/bitgo_fee_provider.dart';

class BitcoinFeeService {
  final List<FeeProvider> _providers;

  BitcoinFeeService({List<FeeProvider>? providers})
    : _providers = providers ?? [BlockstreamFeeProvider(), BitgoFeeProvider()];

  Future<BitcoinFeeEstimate?> fetchFeeEstimate() async {
    for (int i = 0; i < _providers.length; i++) {
      final provider = _providers[i];

      try {
        final estimate = await provider.fetchFeeEstimate();

        if (estimate != null) {
          return estimate;
        }

        if (i < _providers.length - 1 && kDebugMode) {
          print('[BitcoinFeeService] Trying next provider...');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[BitcoinFeeService] Provider ${provider.providerName} error: $e',
          );
        }
      }
    }

    if (kDebugMode) {
      print('[BitcoinFeeService] All providers failed, returning null');
    }

    return null;
  }

  BitcoinFeeEstimate getDefaultFeeEstimate() {
    return BitcoinFeeEstimate(
      lowFeeSatPerVByte: 1,
      mediumFeeSatPerVByte: 3,
      fastFeeSatPerVByte: 5,
      feeByBlockTarget: {'1': 5.0, '3': 3.0, '6': 2.0, '144': 1.0},
    );
  }
}
