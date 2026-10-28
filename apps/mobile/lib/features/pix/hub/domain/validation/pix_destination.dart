import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_key_validator.dart';

/// What the single destination field of the send flow holds.
enum PixDestinationKind {
  /// The field is empty.
  empty,

  /// A Pix key in a valid format.
  key,

  /// A well-formed Pix Copy and Paste code.
  code,

  /// 11 digits that are a valid CPF and also a Brazilian mobile number. The
  /// user must say which one it is.
  cpfOrPhone,

  /// Text that is neither a valid key nor a valid code.
  invalid,
}

/// The reading of the destination field.
class PixDestination {
  final PixDestinationKind kind;

  /// The key reading. For [PixDestinationKind.cpfOrPhone] it is the CPF.
  /// For [PixDestinationKind.invalid] it carries the key error, unless the
  /// text looked like a code.
  final PixKeyValidation? key;

  /// The phone reading of a [PixDestinationKind.cpfOrPhone] number.
  final PixKeyValidation? phone;

  /// The parsed code, for [PixDestinationKind.code] and for a text that looked
  /// like a code but failed its checks.
  final PixBrCode? code;

  const PixDestination._(this.kind, {this.key, this.phone, this.code});

  /// True when the field can start the flow without another choice.
  bool get isReady =>
      kind == PixDestinationKind.key || kind == PixDestinationKind.code;
}

/// Reads the destination field: a Pix key of any type, or a pasted code.
///
/// The field has no key type selector, so this class detects the type. The
/// checks are local format checks only. The Pix provider confirms the key
/// when the backend creates the withdrawal.
class PixDestinationParser {
  const PixDestinationParser._();

  /// Every Pix Copy and Paste code starts with the payload format indicator.
  static const String _codePrefix = '0002';

  static final RegExp _numericForm = RegExp(r'^[0-9().\s/-]+$');

  /// Brazilian area codes (DDD) in use, from the ANATEL numbering plan.
  static const Set<String> _areaCodes = {
    '11', '12', '13', '14', '15', '16', '17', '18', '19', //
    '21', '22', '24', '27', '28', //
    '31', '32', '33', '34', '35', '37', '38', //
    '41', '42', '43', '44', '45', '46', '47', '48', '49', //
    '51', '53', '54', '55', //
    '61', '62', '63', '64', '65', '66', '67', '68', '69', //
    '71', '73', '74', '75', '77', '79', //
    '81', '82', '83', '84', '85', '86', '87', '88', '89', //
    '91', '92', '93', '94', '95', '96', '97', '98', '99', //
  };

  static PixDestination parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const PixDestination._(PixDestinationKind.empty);
    }

    if (trimmed.startsWith(_codePrefix) &&
        trimmed.length >= PixBrCodeParser.minimumLength) {
      final code = PixBrCodeParser.parse(trimmed);
      return PixDestination._(
        code.isStructurallyValid
            ? PixDestinationKind.code
            : PixDestinationKind.invalid,
        code: code,
      );
    }

    // Digits without a plus sign. A Pix phone key is a mobile number, which
    // has 11 digits in Brazil, so 11 digits are a CPF or a mobile. 14 digits
    // are a CNPJ. Any other length is incomplete. A number with the country
    // code needs the plus sign, so the field mask never has to guess.
    if (_numericForm.hasMatch(trimmed)) {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 11) return _elevenDigits(trimmed, digits);
      if (digits.length == 14) {
        return _key(PixKeyValidator.validateAs(PixKeyType.cnpj, trimmed));
      }
      return PixDestination._(
        PixDestinationKind.invalid,
        key: PixKeyValidation(
          normalized: trimmed,
          error: PixKeyValidationError.unrecognized,
        ),
      );
    }

    return _key(PixKeyValidator.validate(trimmed));
  }

  /// A mobile number has a real area code and then a 9. A CPF can have the
  /// same shape, so a valid CPF with that shape is ambiguous.
  static PixDestination _elevenDigits(String trimmed, String digits) {
    final cpf = PixKeyValidator.validateAs(PixKeyType.cpf, trimmed);
    final looksLikeMobile =
        _areaCodes.contains(digits.substring(0, 2)) && digits[2] == '9';
    if (!looksLikeMobile) return _key(cpf);

    final phone = PixKeyValidator.validateAs(PixKeyType.phone, trimmed);
    if (!cpf.isValid) return _key(phone);
    return PixDestination._(
      PixDestinationKind.cpfOrPhone,
      key: cpf,
      phone: phone,
    );
  }

  static PixDestination _key(PixKeyValidation validation) => PixDestination._(
    validation.isValid ? PixDestinationKind.key : PixDestinationKind.invalid,
    key: validation,
  );
}
