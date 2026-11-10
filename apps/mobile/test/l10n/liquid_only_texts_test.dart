import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Texts that may still name Lightning: the legal documents, the errors
/// that reject a Lightning destination, the name of a sync source, and the
/// legacy PIX send screen, which no route opens.
bool _mayNameLightning(String key) =>
    key.startsWith('terms_') ||
    key.startsWith('privacy_') ||
    key.startsWith('qr_validation_') ||
    key == 'wallet_import_datasource_lightning' ||
    key == 'send_pix_lightning_info';

void main() {
  for (final language in ['pt', 'en', 'es']) {
    test('$language: the wallet names L-BTC, not Bitcoin L2 or LBTC, and '
        'offers no Lightning', () {
      final texts =
          jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
              as Map<String, dynamic>;

      for (final MapEntry(:key, :value) in texts.entries) {
        if (key.startsWith('@') || value is! String) continue;
        expect(value, isNot(contains('Bitcoin L2')), reason: key);
        expect(value, isNot(contains('BTC L2')), reason: key);
        // The ticker is L-BTC, with its hyphen.
        expect(value, isNot(matches(RegExp(r'(?<![-\w])LBTC'))), reason: key);
        if (!_mayNameLightning(key)) {
          expect(
            value.toLowerCase(),
            isNot(contains('lightning')),
            reason: key,
          );
        }
      }
    });
  }
}
