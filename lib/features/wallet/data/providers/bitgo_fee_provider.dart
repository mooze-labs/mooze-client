import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/interfaces/fee_provider.dart';
import '../../domain/models/bitcoin_fee_estimate.dart';

class BitgoFeeProvider implements FeeProvider {
  static const String _apiUrl = 'https://www.bitgo.com/api/v2/btc/tx/fee';
  static const Duration _timeout = Duration(seconds: 5);

  @override
  String get providerName => 'BitGo';

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
    final feeByBlock = (json['feeByBlockTarget'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as int) / 1000),
    );

    final fast = feeByBlock['1']?.ceil() ?? 4;
    final medium = feeByBlock['3']?.ceil() ?? 3;
    final low = 1;

    return BitcoinFeeEstimate(
      lowFeeSatPerVByte: low,
      mediumFeeSatPerVByte: medium,
      fastFeeSatPerVByte: fast,
      feeByBlockTarget: feeByBlock,
    );
  }
}
