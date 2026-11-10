import 'package:mooze_mobile/features/wallet/data/services/bitcoin_fee_service.dart';
import 'package:mooze_mobile/features/wallet/domain/interfaces/fee_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/models/bitcoin_fee_estimate.dart';

/// Bitcoin fee rates of economic 2, normal 5 and fast 9 sat/vB.
BitcoinFeeEstimate fixedBitcoinFees() => BitcoinFeeEstimate(
  lowFeeSatPerVByte: 2,
  mediumFeeSatPerVByte: 5,
  fastFeeSatPerVByte: 9,
  feeByBlockTarget: const {},
);

/// A [FeeProvider] that answers [fixedBitcoinFees] and counts the fetches.
class FixedFeeProvider implements FeeProvider {
  int fetches = 0;

  /// A [BitcoinFeeService] over this provider alone.
  BitcoinFeeService get service => BitcoinFeeService(providers: [this]);

  @override
  String get providerName => 'fixed';

  @override
  Future<BitcoinFeeEstimate?> fetchFeeEstimate() async {
    fetches++;
    return fixedBitcoinFees();
  }
}
