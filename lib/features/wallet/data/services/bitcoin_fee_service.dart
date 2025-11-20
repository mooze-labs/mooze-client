import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class BitcoinFeeEstimate {
  final int lowFeeSatPerVByte;
  final int mediumFeeSatPerVByte;
  final int fastFeeSatPerVByte;
  final Map<String, double> feeByBlockTarget;

  BitcoinFeeEstimate({
    required this.lowFeeSatPerVByte,
    required this.mediumFeeSatPerVByte,
    required this.fastFeeSatPerVByte,
    required this.feeByBlockTarget,
  });

  factory BitcoinFeeEstimate.fromBlockstream(Map<String, dynamic> json) {
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

  factory BitcoinFeeEstimate.fromBitgo(Map<String, dynamic> json) {
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

class BitcoinFeeService {
  static const String _blockstreamApiUrl =
      'https://blockstream.info/api/fee-estimates';
  static const String _bitgoApiUrl = 'https://www.bitgo.com/api/v2/btc/tx/fee';

  Future<BitcoinFeeEstimate?> fetchFeeEstimate() async {
    try {
      final response = await http
          .get(Uri.parse(_blockstreamApiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final estimate = BitcoinFeeEstimate.fromBlockstream(data);

        if (kDebugMode) {
          print('[BitcoinFeeService] Blockstream API success:');
          print('  - Low: ${estimate.lowFeeSatPerVByte} sat/vB');
          print('  - Medium: ${estimate.mediumFeeSatPerVByte} sat/vB');
          print('  - Fast: ${estimate.fastFeeSatPerVByte} sat/vB');
        }

        return estimate;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BitcoinFeeService] Blockstream API failed: $e');
        print('[BitcoinFeeService] Trying BitGo fallback...');
      }
    }

    // Fallback to BitGo
    try {
      final response = await http
          .get(Uri.parse(_bitgoApiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final estimate = BitcoinFeeEstimate.fromBitgo(data);

        if (kDebugMode) {
          print('[BitcoinFeeService] BitGo API success:');
          print('  - Low: ${estimate.lowFeeSatPerVByte} sat/vB');
          print('  - Medium: ${estimate.mediumFeeSatPerVByte} sat/vB');
          print('  - Fast: ${estimate.fastFeeSatPerVByte} sat/vB');
        }

        return estimate;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BitcoinFeeService] BitGo API also failed: $e');
      }
    }

    if (kDebugMode) {
      print('[BitcoinFeeService] All APIs failed, returning null');
    }

    return null;
  }
}
