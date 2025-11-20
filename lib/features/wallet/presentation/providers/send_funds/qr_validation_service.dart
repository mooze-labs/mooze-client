/// Service for validating QR code data across different blockchain networks
class QrValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? cleanedData;

  const QrValidationResult({
    required this.isValid,
    this.errorMessage,
    this.cleanedData,
  });

  factory QrValidationResult.valid(String cleanedData) {
    return QrValidationResult(isValid: true, cleanedData: cleanedData);
  }

  factory QrValidationResult.invalid(String errorMessage) {
    return QrValidationResult(isValid: false, errorMessage: errorMessage);
  }
}

class QrValidationService {
  /// Validates QR code data and returns a result with error messages for unsupported formats
  static QrValidationResult validateQrData(String data) {
    if (data.isEmpty) {
      return QrValidationResult.invalid('QR code vazio');
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
        'Lightning com símbolos especiais (₿, #, \$) não é suportado',
      );
    }

    // Check for BIP 353 LNURL formats that are not supported
    if (_isUnsupportedBip353(data)) {
      return QrValidationResult.invalid(
        'Formato LNURL BIP 353 não é suportado no momento. '
        'Use um endereço Lightning válido ou LNURL de walletofsatoshi.com',
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

    return QrValidationResult.invalid('Formato de QR code não reconhecido');
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
      return QrValidationResult.invalid('Invoice BOLTZ inválido');
    }

    String remaining = lowerInvoice.substring(4);

    // Look for amount in the invoice
    bool hasAmount = false;
    final multipliers = ['m', 'u', 'n', 'p'];

    for (String mult in multipliers) {
      String pattern = mult + '1';
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
      return QrValidationResult.invalid(
        'Invoice BOLTZ sem valor não é suportado. '
        'Por favor, gere um invoice com valor definido',
      );
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
        return QrValidationResult.invalid(
          'Endereço Liquid inválido no QR code',
        );
      }

      // Asset ID is optional, but if present, we accept it
      // The amount detection service will handle asset ID parsing

      return QrValidationResult.valid(data);
    } catch (e) {
      return QrValidationResult.invalid(
        'Erro ao processar QR Liquid: formato inválido',
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
        return QrValidationResult.invalid(
          'Endereço Bitcoin inválido no QR code',
        );
      }

      return QrValidationResult.valid(data);
    } catch (e) {
      return QrValidationResult.invalid(
        'Erro ao processar QR Bitcoin: formato inválido',
      );
    }
  }

  /// Validates Lightning invoice
  static QrValidationResult _validateLightningInvoice(String invoice) {
    if (invoice.length < 10) {
      return QrValidationResult.invalid('Lightning invoice muito curto');
    }

    // Strip lightning: prefix if present
    String cleanInvoice = invoice;
    if (invoice.toLowerCase().startsWith('lightning:')) {
      cleanInvoice = invoice.substring(10);
    }

    return QrValidationResult.valid(cleanInvoice);
  }

  /// Validates LNURL
  static QrValidationResult _validateLnurl(String lnurl) {
    // Check for supported LNURL providers
    final lower = lnurl.toLowerCase();

    if (lower.contains('@walletofsatoshi.com')) {
      return QrValidationResult.valid(lnurl);
    }

    // Generic LNURL might work
    if (lower.startsWith('lnurl') && !lower.contains('@')) {
      return QrValidationResult.valid(lnurl);
    }

    return QrValidationResult.invalid(
      'LNURL não suportado. Use walletofsatoshi.com ou outro provedor compatível',
    );
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
