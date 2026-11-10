import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _languages = ['pt', 'en', 'es'];

/// The top-level keys of the translation file of [language], in file
/// order. A JSON decoder keeps only the last of two equal keys, so the
/// keys are read from the text.
List<String> _rawKeys(String language) => [
  for (final match in RegExp(
    r'^  "([^"]+)"\s*:',
    multiLine: true,
  ).allMatches(File('lib/l10n/app_$language.arb').readAsStringSync()))
    match.group(1)!,
];

void main() {
  for (final language in _languages) {
    test('$language: no key appears twice, so none hides another', () {
      final seen = <String>{};
      final repeated = [
        for (final key in _rawKeys(language))
          if (!seen.add(key)) key,
      ];

      expect(repeated, isEmpty);
    });
  }

  test('every language has the same texts', () {
    Set<String> textKeys(String language) => {
      for (final key
          in (jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
                  as Map<String, dynamic>)
              .keys)
        if (!key.startsWith('@')) key,
    };

    final portuguese = textKeys('pt');
    for (final language in _languages.skip(1)) {
      expect(textKeys(language), portuguese, reason: language);
    }
  });
}
