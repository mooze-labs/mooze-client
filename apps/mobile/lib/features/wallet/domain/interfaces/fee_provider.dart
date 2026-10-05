import '../models/bitcoin_fee_estimate.dart';

abstract class FeeProvider {
  String get providerName;
  Future<BitcoinFeeEstimate?> fetchFeeEstimate();
}
