import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/setup/domain/seed_qr.dart';

/// Test vectors of the SeedQR specification. The entropy of each vector was
/// computed independently, from its digits.
const _vectors = [
  (
    phrase:
        'attack pizza motion avocado network gather crop fresh patrol '
        'unusual wild holiday candy pony ranch winter theme error hybrid van '
        'cereal salon goddess expire',
    digits:
        '0115132511540127119007710415074212891906200808700266134314202016'
        '17920614089619290300152408010643',
    entropy: '0e74b64107f94cc0ccfae6a13dcbec3662154fec67e0e00999c07892597d190a',
  ),
  (
    phrase:
        'atom solve joy ugly ankle message setup typical bean era cactus '
        'various odor refuse element afraid meadow quick medal plate wisdom '
        'swap noble shallow',
    digits:
        '0114165509641888007311191572188701560610025619321225144305730036'
        '11011405110613292018175411971576',
    entropy: '0e59dde276009317f1275f1389888078c99368d1e82489b5f629531fc5b6a56e',
  ),
  (
    phrase:
        'sound federal bonus bleak light raise false engage round stock '
        'update render quote truck quality fringe palace foot recipe labor '
        'glow tortoise potato still',
    digits:
        '1662067502030188103614170658059415071712190814561408186514010744'
        '12730727143709940798183613501710',
    entropy: 'cfca8c658bc81962549252bc7ac3ba5b0b01d26bcae89f2b5ecebe263dcb2a36',
  ),
  (
    phrase:
        'forum undo fragile fade shy sign arrest garment culture tube off '
        'merit',
    digits: '073318950739065415961602009907670428187212261116',
    entropy: '5bbd9d71a8ec7990831aff359d426545',
  ),
  (
    phrase:
        'good battle boil exact add seed angle hurry success glad carbon '
        'whisper',
    digits: '080301540200062600251559007008931730078802752004',
    entropy: '6462686427203385c2337dd84c5089fd',
  ),
  (
    phrase:
        'approve fruit lens brass ring actual stool coin doll boss strong rate',
    digits: '008607501025021714880023171503630517020917211425',
    entropy: '0acbba008d9ba005f5996b40a3475cd9',
  ),
  (
    phrase:
        'dignity utility vacant shiver thought canoe feel multiply item youth '
        'actor coyote',
    digits: '049619221923158517990268067811630950204300210397',
    entropy: '3e1e0bc1e31e0e4315348b76dfec0a98',
  ),
  (
    phrase:
        'corn voice scrap arrow original diamond trial property benefit '
        'choose junk lock',
    digits: '038719631547010112530489185713790169032209701051',
    entropy: '307eaf058659ca7a7a0d63152509e541',
  ),
  (
    phrase:
        'vocal tray giggle tool duck letter category pattern train magnet '
        'excite swamp',
    digits: '196218530783182905421028028912901848107106301753',
    entropy: 'f55cf587f2543d01090d0ae710bd3b6d',
  ),
];

Uint8List _hex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

void main() {
  group('Standard SeedQR', () {
    test('reads the phrase of every vector of the specification', () {
      for (final vector in _vectors) {
        expect(SeedQr.decode(text: vector.digits), right(vector.phrase));
      }
    });

    test('ignores the spaces around the digits', () {
      final vector = _vectors[3];
      expect(SeedQr.decode(text: ' ${vector.digits}\n'), right(vector.phrase));
    });

    test('refuses digits that do not make 12 or 24 words', () {
      final digits = _vectors[3].digits;
      for (final text in [
        digits.substring(0, 47),
        '${digits}0000',
        // 18 words: valid in BIP39, not in a SeedQR.
        '$digits${digits.substring(0, 24)}',
      ]) {
        expect(SeedQr.decode(text: text), left(SeedQrError.unsupported));
      }
    });

    test('refuses an index past the end of the wordlist', () {
      final text = '2048${_vectors[3].digits.substring(4)}';
      expect(SeedQr.decode(text: text), left(SeedQrError.invalidPhrase));
    });

    test('refuses a phrase with a wrong checksum', () {
      expect(SeedQr.decode(text: '0000' * 12), left(SeedQrError.invalidPhrase));
    });

    test('refuses a text that is not a SeedQR', () {
      for (final text in ['not a seed', 'https://mooze.app', '']) {
        expect(SeedQr.decode(text: text), left(SeedQrError.unsupported));
      }
    });
  });

  group('CompactSeedQR', () {
    test(
      'reads the entropy of every vector, with \\x00, \\n and \\r in it',
      () {
        for (final vector in _vectors) {
          expect(
            SeedQr.decode(bytes: _hex(vector.entropy)),
            right(vector.phrase),
          );
        }
      },
    );

    test('reads the BIP39 vectors of 12 and 24 words', () {
      final cases = {
        '00' * 16: '${'abandon ' * 11}about',
        '7f' * 16:
            'legal winner thank year wave sausage worth useful legal winner '
            'thank yellow',
        'ff' * 16: '${'zoo ' * 11}wrong',
        '00' * 32: '${'abandon ' * 23}art',
        'ff' * 32: '${'zoo ' * 23}vote',
      };
      cases.forEach((entropy, phrase) {
        expect(SeedQr.decode(bytes: _hex(entropy)), right(phrase));
      });
    });

    test('reads the bytes as the QR stores them, with the mode and the '
        'length before the data, as some readers return them', () {
      // Data codewords computed independently: QR 1-L (12 words), 2-L
      // (24 words) and 2-M (12 words).
      final cases = {
        '4105bbd9d71a8ec7990831aff359d4265450ec': _vectors[3].phrase,
        '4200e74b64107f94cc0ccfae6a13dcbec3662154fec67e0e00999c07892597d19'
                '0a0':
            _vectors[0].phrase,
        '4100acbba008d9ba005f5996b40a3475cd90ec11ec11ec11ec11ec11':
            _vectors[5].phrase,
      };
      cases.forEach((codewords, phrase) {
        expect(SeedQr.decode(bytes: _hex(codewords)), right(phrase));
      });
    });

    test('refuses bytes that do not make 12 or 24 words', () {
      for (final length in [0, 15, 17, 20, 24, 33]) {
        expect(
          SeedQr.decode(bytes: Uint8List(length)..fillRange(0, length, 0x9c)),
          left(SeedQrError.unsupported),
        );
      }
    });

    test('refuses a stored segment of another mode or another length', () {
      for (final codewords in [
        // Numeric mode.
        '1105bbd9d71a8ec7990831aff359d4265450ec',
        // 20 bytes, the entropy of 15 words.
        '4149c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c0ec11ec11ec11',
        // No terminator after the data.
        '4105bbd9d71a8ec7990831aff359d4265459ec',
        // A segment cut short.
        '4105bbd9d71a8ec7990831aff359d42654',
      ]) {
        expect(
          SeedQr.decode(bytes: _hex(codewords)),
          left(SeedQrError.unsupported),
        );
      }
    });

    test('refuses a short text, which is not entropy', () {
      final text = Uint8List.fromList(utf8.encode('Hello, SeedQR!!!'));
      expect(SeedQr.decode(bytes: text), left(SeedQrError.unsupported));
      expect(
        SeedQr.decode(bytes: _hex('41048656c6c6f2c205365656451522121210ec')),
        left(SeedQrError.unsupported),
      );
    });
  });

  group('phrase in text, as BlueWallet shows it in its backup QR', () {
    test('reads phrases of 12 and 24 words', () {
      for (final vector in [_vectors[0], _vectors[3]]) {
        expect(SeedQr.decode(text: vector.phrase), right(vector.phrase));
      }
    });

    test('reads phrases of 15, 18 and 21 words, as the import does', () {
      // The 18-word phrases are BIP39 vectors; the others were computed
      // independently.
      for (final phrase in [
        '${'abandon ' * 14}address',
        '${'abandon ' * 17}agent',
        'legal winner thank year wave sausage worth useful legal winner '
            'thank year wave sausage worth useful legal will',
        '${'abandon ' * 20}admit',
      ]) {
        expect(SeedQr.decode(text: phrase), right(phrase));
      }
    });

    test('takes line breaks, extra spaces and capitals', () {
      final phrase = _vectors[3].phrase;
      final text = ' ${phrase.toUpperCase().replaceAll(' ', '\n  ')} ';
      expect(SeedQr.decode(text: text), right(phrase));
    });

    test('refuses words that do not form a valid phrase', () {
      for (final text in [
        // Wrong checksum.
        'abandon ' * 11 + 'abandon',
        // A word out of the wordlist.
        _vectors[3].phrase.replaceFirst('forum', 'forums'),
      ]) {
        expect(SeedQr.decode(text: text), left(SeedQrError.invalidPhrase));
      }
    });

    test('refuses a text that is not a phrase', () {
      final phrase = _vectors[3].phrase;
      for (final text in [
        // One word short.
        phrase.substring(phrase.indexOf(' ') + 1),
        // Twelve words, one of them a link.
        'please visit https://mooze.app now to read all twelve words of '
            'this page',
      ]) {
        expect(SeedQr.decode(text: text), left(SeedQrError.unsupported));
      }
    });

    test('reads the text before the bytes, which a text code also has', () {
      final phrase = _vectors[3].phrase;
      expect(
        SeedQr.decode(
          text: phrase,
          bytes: Uint8List.fromList(utf8.encode(phrase)),
        ),
        right(phrase),
      );
    });
  });

  test('prefers the digits of a Standard SeedQR to its bytes', () {
    final vector = _vectors[3];
    expect(
      SeedQr.decode(text: vector.digits, bytes: _hex(_vectors[4].entropy)),
      right(vector.phrase),
    );
  });

  test('refuses a code with no content', () {
    expect(SeedQr.decode(), left(SeedQrError.unsupported));
    expect(
      SeedQr.decode(text: '', bytes: Uint8List(0)),
      left(SeedQrError.unsupported),
    );
  });
}
