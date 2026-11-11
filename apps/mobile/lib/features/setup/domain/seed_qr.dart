import 'dart:typed_data';

import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:fpdart/fpdart.dart';

/// Why a scanned code gives no recovery phrase. It deliberately carries no
/// part of the code, which may hold a seed.
enum SeedQrError {
  /// The code holds no recovery phrase that the app can read.
  unsupported,

  /// The words do not form a valid BIP39 phrase.
  invalidPhrase,
}

/// Reads the BIP39 recovery phrase of a scanned code:
///
/// - Standard SeedQR: four digits per word, the index of the word in the
///   BIP39 English wordlist.
/// - CompactSeedQR: the entropy of the phrase, 16 or 32 bytes.
/// - The phrase in plain text, as in BlueWallet's backup QR.
///
/// SeedQR specification:
/// https://github.com/SeedSigner/seedsigner/blob/dev/docs/seed_qr/README.md
abstract final class SeedQr {
  /// Returns the phrase with one space between words.
  static Either<SeedQrError, String> decode({String? text, Uint8List? bytes}) {
    final trimmed = text?.trim();
    if (trimmed != null && _standard.hasMatch(trimmed)) {
      return _phraseOfDigits(trimmed);
    }
    final words = trimmed == null ? null : _wordsOf(trimmed);
    if (words != null) return _checked(words);
    final entropy = bytes == null ? null : _entropyOf(bytes);
    if (entropy == null) return left(SeedQrError.unsupported);
    return right(Mnemonic(entropy, Language.english).sentence);
  }

  static final _standard = RegExp(r'^(?:\d{48}|\d{96})$');
  static final _spaces = RegExp(r'\s+');
  static final _letters = RegExp(r'^[a-z]+$');
  static const _phraseLengths = {12, 15, 18, 21, 24};

  static Either<SeedQrError, String> _phraseOfDigits(String digits) {
    final wordlist = Language.english.list;
    final words = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      final index = int.parse(digits.substring(i, i + 4));
      if (index >= wordlist.length) return left(SeedQrError.invalidPhrase);
      words.add(wordlist[index]);
    }
    return _checked(words);
  }

  static List<String>? _wordsOf(String text) {
    final words = text.toLowerCase().split(_spaces);
    if (!_phraseLengths.contains(words.length)) return null;
    return words.every(_letters.hasMatch) ? words : null;
  }

  static Either<SeedQrError, String> _checked(List<String> words) {
    final phrase = words.join(' ');
    try {
      Mnemonic.fromSentence(phrase, Language.english);
    } catch (_) {
      // The exception message holds the phrase, so it must not reach a log
      // or a crash report.
      return left(SeedQrError.invalidPhrase);
    }
    return right(phrase);
  }

  /// Some readers return the data of a binary code alone, others the segment
  /// as the QR stores it, with its header.
  static List<int>? _entropyOf(Uint8List bytes) {
    final data = _isEntropyLength(bytes.length) ? bytes : _storedSegment(bytes);
    // Rejects a short text: 16 random bytes are all printable only about once
    // in eight million codes.
    if (data == null || data.every(_isPrintable)) return null;
    return data;
  }

  static bool _isEntropyLength(int length) => length == 16 || length == 32;

  static bool _isPrintable(int byte) => byte >= 0x20 && byte <= 0x7e;

  /// The data of a byte segment as the QR stores it: a 4-bit mode (0100), an
  /// 8-bit length (QR versions 1 to 9), the data and a 4-bit zero terminator.
  /// The data is therefore four bits off the byte boundaries.
  static List<int>? _storedSegment(Uint8List raw) {
    if (raw.length < 2 || (raw[0] >> 4) != 0x4) return null;
    final length = ((raw[0] & 0x0f) << 4) | (raw[1] >> 4);
    if (!_isEntropyLength(length) || raw.length < length + 2) return null;
    final data = [
      for (var i = 1; i <= length; i++)
        ((raw[i] & 0x0f) << 4) | (raw[i + 1] >> 4),
    ];
    final terminator = raw[length + 1] & 0x0f;
    return terminator == 0 ? data : null;
  }
}
