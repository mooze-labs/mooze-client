import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class AmountDetectionResult {
  final int? amountInSats;
  final Asset? asset;
  final String? label;
  final String? message;

  const AmountDetectionResult({
    this.amountInSats,
    this.asset,
    this.label,
    this.message,
  });

  bool get hasAmount => amountInSats != null && amountInSats! > 0;

  @override
  String toString() =>
      'AmountDetectionResult(amount: $amountInSats sats, asset: $asset)';
}

class AmountDetectionService {
  static AmountDetectionResult detectAmount(String input) {
    if (input.isEmpty) return const AmountDetectionResult();

    final cleanInput = input.trim();
    if (cleanInput.toLowerCase().startsWith('lnbc')) {
      return _extractLightningAmount(cleanInput);
    }
    if (cleanInput.toLowerCase().startsWith('bitcoin:') ||
        cleanInput.toLowerCase().startsWith('liquidnetwork:') ||
        cleanInput.toLowerCase().startsWith('liquid:')) {
      return _extractBip21Amount(cleanInput);
    }

    if (cleanInput.contains('?')) {
      return _extractQueryParameters(cleanInput);
    }

    return const AmountDetectionResult();
  }

  /// Extracts amount from Lightning Network invoices (BOLT11)
  static AmountDetectionResult _extractLightningAmount(String invoice) {
    try {
      final lowerInvoice = invoice.toLowerCase();

      if (!lowerInvoice.startsWith('lnbc')) {
        return const AmountDetectionResult();
      }

      String remaining = lowerInvoice.substring(4);

      // Find the '1' separator that marks the end of amount section
      int separatorIndex = -1;

      // Look for known multipliers followed by '1'
      final multipliers = ['m', 'u', 'n', 'p'];
      for (String mult in multipliers) {
        String pattern = mult + '1';
        int index = remaining.indexOf(pattern);
        if (index > 0) {
          String beforeMult = remaining.substring(0, index);
          if (RegExp(r'^\d+$').hasMatch(beforeMult)) {
            separatorIndex = index + 1;
            break;
          }
        }
      }

      // If no multiplier found, look for numbers followed by '1'
      if (separatorIndex == -1) {
        for (int i = 1; i < remaining.length; i++) {
          if (remaining[i] == '1') {
            String beforeOne = remaining.substring(0, i);
            if (RegExp(r'^\d+$').hasMatch(beforeOne) && beforeOne.length > 1) {
              separatorIndex = i;
              break;
            }
          }
        }
      }

      if (separatorIndex == -1) {
        return const AmountDetectionResult();
      }

      String amountSection = remaining.substring(0, separatorIndex);

      if (amountSection.isEmpty) {
        return const AmountDetectionResult(asset: Asset.btc);
      }

      double? baseAmount;
      int satoshis = 0;

      if (amountSection.endsWith('m')) {
        // milli-bitcoin (0.001 BTC)
        baseAmount = double.tryParse(
          amountSection.substring(0, amountSection.length - 1),
        );
        if (baseAmount != null) {
          satoshis = (baseAmount * 100000).round();
        }
      } else if (amountSection.endsWith('u')) {
        // micro-bitcoin (0.000001 BTC)
        baseAmount = double.tryParse(
          amountSection.substring(0, amountSection.length - 1),
        );
        if (baseAmount != null) {
          satoshis = (baseAmount * 100).round();
        }
      } else if (amountSection.endsWith('n')) {
        baseAmount = double.tryParse(
          amountSection.substring(0, amountSection.length - 1),
        );
        if (baseAmount != null) {
          satoshis = (baseAmount * 0.1).round();
        }
      } else if (amountSection.endsWith('p')) {
        baseAmount = double.tryParse(
          amountSection.substring(0, amountSection.length - 1),
        );
        if (baseAmount != null) {
          satoshis = (baseAmount * 0.0001).round();
        }
      } else {
        final millisats = int.tryParse(amountSection);
        if (millisats != null) {
          satoshis = (millisats / 1000).round();
        }
      }

      if (satoshis > 0) {
        return AmountDetectionResult(amountInSats: satoshis, asset: Asset.btc);
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return const AmountDetectionResult(asset: Asset.btc);
  }

  static AmountDetectionResult _extractBip21Amount(String uri) {
    try {
      final parsedUri = Uri.parse(uri);
      final queryParams = parsedUri.queryParameters;

      Asset asset = Asset.btc;
      if (uri.toLowerCase().startsWith('liquidnetwork:') ||
          uri.toLowerCase().startsWith('liquid:')) {
        asset = Asset.btc;
      }

      final amountStr = queryParams['amount'];
      if (amountStr != null) {
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          final satoshis = (amount * 100000000).round();

          return AmountDetectionResult(
            amountInSats: satoshis,
            asset: asset,
            label: queryParams['label'],
            message: queryParams['message'],
          );
        }
      }

      final assetId = queryParams['assetid'];
      if (assetId != null) {
        if (assetId ==
            'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2') {
          asset = Asset.usdt; // USDT on Liquid
        } else if (assetId ==
            '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d') {
          asset = Asset.btc;
        }
      }

      return AmountDetectionResult(
        asset: asset,
        label: queryParams['label'],
        message: queryParams['message'],
      );
    } catch (e) {
      // Ignore parsing errors
    }

    return const AmountDetectionResult();
  }

  /// Extracts query parameters from simple addresses
  static AmountDetectionResult _extractQueryParameters(String address) {
    try {
      final parts = address.split('?');
      if (parts.length != 2) return const AmountDetectionResult();

      final baseAddress = parts[0];
      final queryString = parts[1];

      // Parse query parameters manually
      final params = <String, String>{};
      for (final param in queryString.split('&')) {
        final keyValue = param.split('=');
        if (keyValue.length == 2) {
          params[keyValue[0]] = Uri.decodeComponent(keyValue[1]);
        }
      }

      Asset asset = Asset.btc;
      if (baseAddress.startsWith('lq1') || baseAddress.startsWith('VJL')) {
        asset = Asset.btc;
      }

      final amountStr = params['amount'];
      if (amountStr != null) {
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          final satoshis = (amount * 100000000).round();

          return AmountDetectionResult(
            amountInSats: satoshis,
            asset: asset,
            label: params['label'],
            message: params['message'],
          );
        }
      }

      return AmountDetectionResult(
        asset: asset,
        label: params['label'],
        message: params['message'],
      );
    } catch (e) {
      // Ignore parsing errors
    }

    return const AmountDetectionResult();
  }
}

final amountDetectionProvider = Provider.family<AmountDetectionResult, String>((
  ref,
  input,
) {
  return AmountDetectionService.detectAmount(input);
});
