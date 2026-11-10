import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// References of the payment links, kept on the device by link id.
///
/// The payment-link API has no reference field, so the text the owner types
/// lives here. A reinstall loses it; the list then shows a generic name.
class PixPaymentLinkReferenceStore {
  static const String _key = 'pix_payment_link_references';

  final SharedPreferences _prefs;

  PixPaymentLinkReferenceStore(this._prefs);

  /// Reference by link id. A damaged entry reads as no references.
  Map<String, String> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const {};
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          if (value is String) key: value,
      };
    } on FormatException {
      return const {};
    }
  }

  Future<void> save(String id, String reference) {
    return _prefs.setString(_key, jsonEncode({...load(), id: reference}));
  }
}
