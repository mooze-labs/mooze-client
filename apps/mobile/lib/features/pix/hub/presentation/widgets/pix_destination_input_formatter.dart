import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_destination.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';

/// Live mask of the destination field of the send flow.
///
/// The field takes any Pix key, so the mask depends on what the user types:
/// - Digits: a CPF mask up to 11 digits, a CNPJ mask from 12 to 14.
/// - 11 digits that read as a mobile number: `(11) 99999-8888`.
/// - A leading plus sign: `+55 (11) 99999-8888`.
/// - A letter or an `@`: no mask. Emails and random keys stay as typed.
///
/// The mask never changes the digits. It only adds separators.
class PixDestinationInputFormatter extends TextInputFormatter {
  /// Text made of digits and mask characters only.
  static final RegExp _maskable = RegExp(r'^\+?[0-9().\s/-]*$');

  /// The first group of a random key: 8 hexadecimal digits and a hyphen. No
  /// mask puts a hyphen after 8 digits, so this shape is a random key.
  static final RegExp _randomKeyStart = RegExp(r'^[0-9a-fA-F]{8}-');

  static const int _maxDocumentDigits = 14;
  static const int _maxPhoneDigits = 13;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (!_maskable.hasMatch(text) || _randomKeyStart.hasMatch(text)) {
      return _leaveMask(oldValue, newValue);
    }

    final plus = text.trimLeft().startsWith('+');
    final typed = _appended(oldValue.text, text);
    final oldDigits = _digits(oldValue.text);

    // A hyphen typed after 8 digits starts a random key: keep it.
    if (!plus && typed == '-' && oldDigits.length == 8) {
      return _collapsed('$oldDigits-');
    }

    var digits = _digits(text);
    final cursor = newValue.selection.end.clamp(0, text.length);
    var digitsBeforeCursor = _digits(text.substring(0, cursor)).length;

    // Backspace over a mask character removes the digit before it, so the
    // mask cannot block the deletion.
    if (text.length < oldValue.text.length &&
        digits == oldDigits &&
        digitsBeforeCursor > 0) {
      digits =
          digits.substring(0, digitsBeforeCursor - 1) +
          digits.substring(digitsBeforeCursor);
      digitsBeforeCursor--;
    }

    if (!plus && digits.length > _maxDocumentDigits) return newValue;

    final formatted = plus ? formatPhoneWithCountry(digits) : _national(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _offsetAfterDigits(formatted, digitsBeforeCursor),
      ),
    );
  }

  /// Formats a mobile number without the country code: `(11) 99999-8888`.
  static String formatMobile(String digits) {
    if (digits.length != 11) return digits;
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-'
        '${digits.substring(7)}';
  }

  /// Formats a phone number with the country code, as the user types it:
  /// `+55 (11) 99999-8888`. Other country codes get the plus sign only.
  static String formatPhoneWithCountry(String digits) {
    if (digits.length <= 2 ||
        !digits.startsWith('55') ||
        digits.length > _maxPhoneDigits) {
      return '+$digits';
    }
    final area = digits.substring(2, digits.length.clamp(2, 4));
    final number = digits.length > 4 ? digits.substring(4) : '';
    final buffer = StringBuffer('+55 ($area');
    if (number.isEmpty) return buffer.toString();
    buffer.write(') ');
    // 8 digits split 4-4 while the user types. The ninth digit of a mobile
    // number moves the hyphen to a 5-4 split.
    final split = number.length == 9 ? 5 : 4;
    if (number.length <= split) {
      buffer.write(number);
    } else {
      buffer
        ..write(number.substring(0, split))
        ..write('-')
        ..write(number.substring(split));
    }
    return buffer.toString();
  }

  /// Formats digits without the plus sign, from the reading of the number.
  static String _national(String digits) {
    if (digits.length == 11) {
      final reading = PixDestinationParser.parse(digits);
      if (reading.kind == PixDestinationKind.key &&
          reading.key?.type == PixKeyType.phone) {
        return formatMobile(digits);
      }
    }
    return formatCpfCnpj(digits);
  }

  /// Removes the mask when the text stops being a number, for example when
  /// the user types the `@` of an email that starts with digits.
  static TextEditingValue _leaveMask(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final old = oldValue.text;
    final oldWasMasked =
        old.isNotEmpty &&
        _maskable.hasMatch(old) &&
        !_randomKeyStart.hasMatch(old);
    if (!oldWasMasked || !newValue.text.startsWith(old)) return newValue;
    final raw =
        old.replaceAll(RegExp(r'[^0-9+]'), '') +
        newValue.text.substring(old.length);
    return _collapsed(raw);
  }

  /// The text added at the end, or null for any other edit.
  static String? _appended(String old, String current) =>
      current.length > old.length && current.startsWith(old)
      ? current.substring(old.length)
      : null;

  static String _digits(String text) => text.replaceAll(RegExp(r'[^0-9]'), '');

  /// The offset right after the [count]-th digit of [text].
  static int _offsetAfterDigits(String text, int count) {
    if (count <= 0) return text.startsWith('+') ? 1 : 0;
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      if (unit >= 0x30 && unit <= 0x39 && ++seen == count) return i + 1;
    }
    return text.length;
  }

  static TextEditingValue _collapsed(String text) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}
