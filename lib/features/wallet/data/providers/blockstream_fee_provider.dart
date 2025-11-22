import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/interfaces/fee_provider.dart';
import '../../domain/models/bitcoin_fee_estimate.dart';

class BlockstreamFeeProvider implements FeeProvider {
  static const String _apiUrl = 'https://blockstream.info/api/fee-estimates';
  static const Duration _timeout = Duration(seconds: 5);

  @override
  String get providerName => 'Blockstream';

  @override
  Future<BitcoinFeeEstimate?> fetchFeeEstimate() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final estimate = _parseResponse(data);

        return estimate;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  BitcoinFeeEstimate _parseResponse(Map<String, dynamic> json) {
    final feeByBlock = json.map((k, v) => MapEntry(k, (v as num).toDouble()));

    final fast = (feeByBlock['1'] ?? feeByBlock['2'] ?? 4.0).ceil();
    final medium = (feeByBlock['3'] ?? feeByBlock['6'] ?? 3.0).ceil();
    final low = (feeByBlock['144'] ?? 1.0).ceil();

    return BitcoinFeeEstimate(
      lowFeeSatPerVByte: low,
      mediumFeeSatPerVByte: medium,
      fastFeeSatPerVByte: fast,
      feeByBlockTarget: feeByBlock,
    );
  }
}
