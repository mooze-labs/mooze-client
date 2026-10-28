/// Why a Pix Copy and Paste code cannot be accepted.
enum PixBrCodeError {
  /// The field is empty.
  empty,

  /// The text is too short to be a Pix code.
  tooShort,

  /// The text does not follow the EMV®QRCPS field structure.
  malformed,

  /// The text has no Pix merchant account field (`BR.GOV.BCB.PIX`).
  notPix,

  /// The final CRC16 does not match the content.
  invalidChecksum,
}

/// A Pix Copy and Paste code after local parsing.
///
/// Only the structure and the CRC16 of the payload are verified here. A code
/// that parses is **not** proven to be payable: the amount, the recipient and
/// the status of the charge are only known by the Pix infrastructure.
class PixBrCode {
  /// The code exactly as the user supplied it.
  final String raw;

  /// The error found, or null when the structure and the CRC are valid.
  final PixBrCodeError? error;

  /// Merchant name (tag 59), when present.
  final String? merchantName;

  /// Merchant city (tag 60), when present.
  final String? merchantCity;

  /// Pix key inside the merchant account field, when present.
  final String? pixKey;

  /// Amount in BRL cents (tag 54), when the code carries a fixed amount.
  final int? amountInCents;

  /// Transaction identifier (tag 62/05), when present.
  final String? transactionId;

  const PixBrCode({
    required this.raw,
    this.error,
    this.merchantName,
    this.merchantCity,
    this.pixKey,
    this.amountInCents,
    this.transactionId,
  });

  bool get isStructurallyValid => error == null;

  /// True when the payer still has to inform the amount.
  bool get hasOpenAmount => amountInCents == null;
}

/// Parses and builds Pix Copy and Paste codes (EMV®QRCPS BR Code).
class PixBrCodeParser {
  const PixBrCodeParser._();

  static const String _pixGui = 'BR.GOV.BCB.PIX';

  /// Shortest payload that can still carry every mandatory field.
  static const int minimumLength = 40;

  /// Reads [input] and reports what can be verified without a network call.
  static PixBrCode parse(String input) {
    // Line breaks come from pasted text, but a space can belong to a field
    // value such as the merchant name, and removing it breaks the lengths.
    final raw = input.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
    if (raw.isEmpty) {
      return PixBrCode(raw: input, error: PixBrCodeError.empty);
    }
    if (raw.length < minimumLength) {
      return PixBrCode(raw: input, error: PixBrCodeError.tooShort);
    }

    final fields = _readFields(raw);
    if (fields == null || !fields.containsKey('00')) {
      return PixBrCode(raw: input, error: PixBrCodeError.malformed);
    }

    final merchantAccount = _firstMerchantAccount(fields);
    if (merchantAccount == null) {
      return PixBrCode(raw: input, error: PixBrCodeError.notPix);
    }

    if (!_hasValidChecksum(raw)) {
      return PixBrCode(raw: input, error: PixBrCodeError.invalidChecksum);
    }

    final additional = _readFields(fields['62'] ?? '') ?? const {};

    return PixBrCode(
      raw: input,
      merchantName: fields['59'],
      merchantCity: fields['60'],
      pixKey: merchantAccount['01'],
      amountInCents: _parseAmount(fields['54']),
      transactionId: additional['05'],
    );
  }

  /// Builds a BR Code payload with a correct CRC16.
  ///
  /// Used by the demonstration dataset so the generated QR Code carries a
  /// well-formed payload instead of decorative text.
  static String build({
    required String pixKey,
    required String merchantName,
    required String merchantCity,
    int? amountInCents,
    String? transactionId,
    String? description,
  }) {
    final accountFields = StringBuffer()
      ..write(_field('00', _pixGui))
      ..write(_field('01', pixKey));
    if (description != null && description.isNotEmpty) {
      accountFields.write(_field('02', _sanitize(description, 72)));
    }

    final payload = StringBuffer()
      ..write(_field('00', '01'))
      ..write(_field('26', accountFields.toString()))
      ..write(_field('52', '0000'))
      ..write(_field('53', '986'));

    if (amountInCents != null) {
      payload.write(_field('54', (amountInCents / 100).toStringAsFixed(2)));
    }

    payload
      ..write(_field('58', 'BR'))
      ..write(_field('59', _sanitize(merchantName, 25)))
      ..write(_field('60', _sanitize(merchantCity, 15)))
      ..write(_field('62', _field('05', _sanitize(transactionId ?? '***', 25))))
      ..write('6304');

    final body = payload.toString();
    return '$body${crc16(body)}';
  }

  /// CRC16/CCITT-FALSE of [payload], as four uppercase hex digits.
  static String crc16(String payload) {
    var crc = 0xFFFF;
    for (final byte in payload.codeUnits) {
      crc ^= byte << 8;
      for (var bit = 0; bit < 8; bit++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static bool _hasValidChecksum(String raw) {
    final marker = raw.length - 8;
    if (marker < 0) return false;
    if (raw.substring(marker, marker + 4) != '6304') return false;
    final body = raw.substring(0, marker + 4);
    final expected = raw.substring(marker + 4).toUpperCase();
    return crc16(body) == expected;
  }

  /// Reads one level of `ID + length + value` fields.
  ///
  /// Returns null when a field announces a length that the text cannot hold.
  static Map<String, String>? _readFields(String payload) {
    final fields = <String, String>{};
    var index = 0;
    while (index + 4 <= payload.length) {
      final id = payload.substring(index, index + 2);
      final lengthText = payload.substring(index + 2, index + 4);
      final length = int.tryParse(lengthText);
      if (length == null) return null;
      final start = index + 4;
      final end = start + length;
      if (end > payload.length) return null;
      fields[id] = payload.substring(start, end);
      index = end;
    }
    return index == payload.length ? fields : null;
  }

  /// Returns the fields of the first merchant account entry that holds the
  /// Pix identifier, searching tags 26 to 51 as the specification allows.
  static Map<String, String>? _firstMerchantAccount(
    Map<String, String> fields,
  ) {
    for (var tag = 26; tag <= 51; tag++) {
      final value = fields[tag.toString().padLeft(2, '0')];
      if (value == null) continue;
      final inner = _readFields(value);
      if (inner != null && inner['00']?.toUpperCase() == _pixGui) {
        return inner;
      }
    }
    return null;
  }

  static int? _parseAmount(String? value) {
    if (value == null) return null;
    final amount = double.tryParse(value);
    if (amount == null) return null;
    return (amount * 100).round();
  }

  static String _field(String id, String value) =>
      '$id${value.length.toString().padLeft(2, '0')}$value';

  /// Keeps only the characters accepted by the BR Code text fields.
  ///
  /// Accented letters become their plain form, because the payload accepts
  /// ASCII only.
  static String _sanitize(String value, int maxLength) {
    final buffer = StringBuffer();
    for (final rune in value.toUpperCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accentFolding[char] ?? char);
    }
    final clean = buffer
        .toString()
        .replaceAll(RegExp(r'[^A-Z0-9 .*-]'), '')
        .trim();
    return clean.length <= maxLength ? clean : clean.substring(0, maxLength);
  }

  static const Map<String, String> _accentFolding = {
    'Á': 'A',
    'À': 'A',
    'Ã': 'A',
    'Â': 'A',
    'Ä': 'A',
    'É': 'E',
    'Ê': 'E',
    'È': 'E',
    'Í': 'I',
    'Î': 'I',
    'Ó': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ö': 'O',
    'Ú': 'U',
    'Ü': 'U',
    'Ç': 'C',
    'Ñ': 'N',
  };
}
