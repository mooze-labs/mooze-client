import 'dart:convert';
import 'package:http/http.dart' as http;

class BitGoFeeEstimate {
  final int lowFeeSatPerVByte;
  final int mediumFeeSatPerVByte;
  final int fastFeeSatPerVByte;
  final Map<String, int> feeByBlockTarget;

  BitGoFeeEstimate({
    required this.lowFeeSatPerVByte,
    required this.mediumFeeSatPerVByte,
    required this.fastFeeSatPerVByte,
    required this.feeByBlockTarget,
  });

  factory BitGoFeeEstimate.fromJson(Map<String, dynamic> json) {
    final feeByBlock = json['feeByBlockTarget'] as Map<String, dynamic>;

    return BitGoFeeEstimate(
      lowFeeSatPerVByte: 1,
      mediumFeeSatPerVByte: (feeByBlock['3'] as int) ~/ 1000,
      fastFeeSatPerVByte: (feeByBlock['1'] as int) ~/ 1000,
      feeByBlockTarget: feeByBlock.map((k, v) => MapEntry(k, v as int)),
    );
  }
}

class BitGoFeeService {
  static const String _apiUrl = 'https://www.bitgo.com/api/v2/btc/tx/fee';

  Future<BitGoFeeEstimate?> fetchFeeEstimate() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BitGoFeeEstimate.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar taxas BitGo: $e');
      return null;
    }
  }

  BitGoFeeEstimate getDefaultFees() {
    return BitGoFeeEstimate(
      lowFeeSatPerVByte: 1,
      mediumFeeSatPerVByte: 3,
      fastFeeSatPerVByte: 5,
      feeByBlockTarget: {
        '1': 5000,
        '2': 4000,
        '3': 3000,
        '6': 2000,
        '144': 1000,
      },
    );
  }
}
