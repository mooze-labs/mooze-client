import 'package:flutter/widgets.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Stable error codes for QR validation failures, decoupled from user-facing copy
enum QrValidationErrorCode {
  empty,
  unrecognized,
  lightningUnsupportedSymbols,
  lnurlBip353Unsupported,
  boltzInvalid,
  boltzNoAmount,
  liquidInvalid,
  liquidFormatError,
  bitcoinInvalid,
  bitcoinFormatError,
  lightningUnsupported,
  lnurlUnsupported,
}

/// Service for validating QR code data across different blockchain networks
class QrValidationResult {
  final bool isValid;
  final QrValidationErrorCode? errorCode;
  final String? cleanedData;

  const QrValidationResult({
    required this.isValid,
    this.errorCode,
    this.cleanedData,
  });

  factory QrValidationResult.valid(String cleanedData) {
    return QrValidationResult(isValid: true, cleanedData: cleanedData);
  }

  factory QrValidationResult.invalid(QrValidationErrorCode code) {
    return QrValidationResult(isValid: false, errorCode: code);
  }

  String localize(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (errorCode) {
      case QrValidationErrorCode.empty:
        return t.qr_validation_empty;
      case QrValidationErrorCode.unrecognized:
        return t.qr_validation_unrecognized;
      case QrValidationErrorCode.lightningUnsupportedSymbols:
        return t.qr_validation_lightning_unsupported_symbols;
      case QrValidationErrorCode.lnurlBip353Unsupported:
        return t.qr_validation_lnurl_bip353_unsupported;
      case QrValidationErrorCode.boltzInvalid:
        return t.qr_validation_boltz_invalid;
      case QrValidationErrorCode.boltzNoAmount:
        return t.qr_validation_boltz_no_amount;
      case QrValidationErrorCode.liquidInvalid:
        return t.qr_validation_liquid_invalid;
      case QrValidationErrorCode.liquidFormatError:
        return t.qr_validation_liquid_format_error;
      case QrValidationErrorCode.bitcoinInvalid:
        return t.qr_validation_bitcoin_invalid;
      case QrValidationErrorCode.bitcoinFormatError:
        return t.qr_validation_bitcoin_format_error;
      case QrValidationErrorCode.lightningUnsupported:
        return t.qr_validation_lightning_unsupported;
      case QrValidationErrorCode.lnurlUnsupported:
        return t.qr_validation_lnurl_unsupported;
      case null:
        return t.qr_validation_invalid_default;
    }
  }
}

class QrValidationService {
  /// Validates QR code data and returns a result with error codes for unsupported formats
  static QrValidationResult validateQrData(String data) {
    if (data.isEmpty) {
      return QrValidationResult.invalid(QrValidationErrorCode.empty);
    }

    final lowerData = data.toLowerCase();

    // Strip lightning: prefix if present for further processing
    String processedData = data;
    if (lowerData.startsWith('lightning:')) {
      processedData = data.substring(10);
    }

    final lowerProcessedData = processedData.toLowerCase();

    // Check for BOLTZ invoices first (must have value)
    if (_isBoltzInvoice(processedData)) {
      return _validateBoltzInvoice(processedData);
    }

    // Check for Lightning invoices with special symbols
    if (_hasUnsupportedLightningSymbols(data)) {
      return QrValidationResult.invalid(
        QrValidationErrorCode.lightningUnsupportedSymbols,
      );
    }

    // Check for BIP 353 LNURL formats that are not supported
    if (_isUnsupportedBip353(data)) {
      return QrValidationResult.invalid(
        QrValidationErrorCode.lnurlBip353Unsupported,
      );
    }

    // Check for Liquid Network BIP21
    if (_isLiquidBip21(data)) {
      return _validateLiquidBip21(data);
    }

    // Check for Bitcoin BIP21
    if (_isBitcoinBip21(data)) {
      return _validateBitcoinBip21(data);
    }

    // Check for valid Lightning invoices (using processed data without lightning: prefix)
    if (lowerProcessedData.startsWith('lnbc')) {
      return _validateLightningInvoice(processedData);
    }

    // Check for LNURL (should be from supported providers)
    if (lowerData.startsWith('lnurl') || lowerData.contains('@')) {
      return _validateLnurl(data);
    }

    // Check for plain addresses
    if (_isPlainAddress(data)) {
      return QrValidationResult.valid(data);
    }

    return QrValidationResult.invalid(QrValidationErrorCode.unrecognized);
  }

  /// Checks if the data is a BOLTZ invoice
  static bool _isBoltzInvoice(String data) {
    final lower = data.toLowerCase();
    return lower.startsWith('lnbc') && data.length > 100;
  }

  /// Validates BOLTZ invoice - must have a value
  static QrValidationResult _validateBoltzInvoice(String invoice) {
    final lowerInvoice = invoice.toLowerCase();

    if (!lowerInvoice.startsWith('lnbc')) {
      return QrValidationResult.invalid(QrValidationErrorCode.boltzInvalid);
    }

    String remaining = lowerInvoice.substring(4);

    // Look for amount in the invoice
    bool hasAmount = false;
    final multipliers = ['m', 'u', 'n', 'p'];

    for (String mult in multipliers) {
      String pattern = '${mult}1';
      int index = remaining.indexOf(pattern);
      if (index > 0) {
        String beforeMult = remaining.substring(0, index);
        if (RegExp(r'^\d+$').hasMatch(beforeMult)) {
          hasAmount = true;
          break;
        }
      }
    }

    // Check for plain number before '1' separator
    if (!hasAmount) {
      for (int i = 1; i < remaining.length && i < 20; i++) {
        if (remaining[i] == '1') {
          String beforeOne = remaining.substring(0, i);
          if (RegExp(r'^\d+$').hasMatch(beforeOne) && beforeOne.length > 1) {
            hasAmount = true;
            break;
          }
        }
      }
    }

    if (!hasAmount) {
      return QrValidationResult.invalid(QrValidationErrorCode.boltzNoAmount);
    }

    return QrValidationResult.valid(invoice);
  }

  /// Checks if the Lightning data has unsupported symbols
  static bool _hasUnsupportedLightningSymbols(String data) {
    final unsupportedSymbols = ['₿', '#', '\$'];
    return unsupportedSymbols.any((symbol) => data.contains(symbol));
  }

  /// Checks if the data is BIP 353 format (phoenixwallet.me style)
  static bool _isUnsupportedBip353(String data) {
    final lower = data.toLowerCase();

    // BIP 353 typically has format like user@domain with specific domains
    if (lower.contains('@phoenixwallet.me')) {
      return true;
    }

    // Check for other BIP 353 patterns that might not be supported
    // BIP 353 uses DNS-based address resolution which may not work with all providers
    if (lower.startsWith('lnurl') &&
        lower.contains('@') &&
        !lower.contains('@walletofsatoshi.com')) {
      return true;
    }

    return false;
  }

  /// Checks if data is Liquid Network BIP21
  static bool _isLiquidBip21(String data) {
    final lower = data.toLowerCase();
    return lower.startsWith('liquidnetwork:') || lower.startsWith('liquid:');
  }

  /// Validates Liquid Network BIP21 format
  static QrValidationResult _validateLiquidBip21(String data) {
    try {
      final uri = Uri.parse(data);

      // Validate that we have a proper address path
      if (uri.path.isEmpty) {
        return QrValidationResult.invalid(QrValidationErrorCode.liquidInvalid);
      }

      // Asset ID is optional, but if present, we accept it
      // The amount detection service will handle asset ID parsing

      return QrValidationResult.valid(data);
    } catch (e) {
      return QrValidationResult.invalid(
        QrValidationErrorCode.liquidFormatError,
      );
    }
  }

  /// Checks if data is Bitcoin BIP21
  static bool _isBitcoinBip21(String data) {
    return data.toLowerCase().startsWith('bitcoin:');
  }

  /// Validates Bitcoin BIP21 format
  static QrValidationResult _validateBitcoinBip21(String data) {
    try {
      final uri = Uri.parse(data);

      // Validate that we have a proper address path
      if (uri.path.isEmpty) {
        return QrValidationResult.invalid(QrValidationErrorCode.bitcoinInvalid);
      }

      return QrValidationResult.valid(data);
    } catch (e) {
      return QrValidationResult.invalid(
        QrValidationErrorCode.bitcoinFormatError,
      );
    }
  }

  /// Validates Lightning invoice
  static QrValidationResult _validateLightningInvoice(String invoice) {
    return QrValidationResult.invalid(
      QrValidationErrorCode.lightningUnsupported,
    );
  }

  /// Validates LNURL
  static QrValidationResult _validateLnurl(String lnurl) {
    return QrValidationResult.invalid(QrValidationErrorCode.lnurlUnsupported);
  }

  /// Checks if data is a plain address (no URI scheme)
  static bool _isPlainAddress(String data) {
    // Bitcoin addresses
    if (data.startsWith('bc1') ||
        data.startsWith('1') ||
        data.startsWith('3') ||
        data.startsWith('tb1') ||
        data.startsWith('2') ||
        data.startsWith('m') ||
        data.startsWith('n')) {
      return true;
    }

    // Liquid addresses
    if (data.startsWith('lq1') ||
        data.startsWith('VJL') ||
        data.startsWith('VT') ||
        data.startsWith('VG') ||
        data.startsWith('H') ||
        data.startsWith('G') ||
        data.startsWith('Az') ||
        data.startsWith('AzQ') ||
        data.startsWith('ert1')) {
      return true;
    }

    return false;
  }
}
