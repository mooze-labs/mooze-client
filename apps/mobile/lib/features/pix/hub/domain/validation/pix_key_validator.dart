import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';

/// Why a typed Pix key cannot be accepted.
enum PixKeyValidationError {
  /// The field is empty.
  empty,

  /// The text does not match any Pix key format.
  unrecognized,

  /// The text looks like a CPF/CNPJ, but the check digits do not match.
  invalidDocument,

  /// The text looks like a phone number with the wrong number of digits.
  invalidPhone,

  /// The text contains an `@`, but is not a valid email address.
  invalidEmail,

  /// The text looks like a random key with the wrong UUID shape.
  invalidRandomKey,
}

/// The outcome of validating a typed Pix key.
class PixKeyValidation {
  /// The detected key type, or null when nothing matched.
  final PixKeyType? type;

  /// The error found, or null when the key is accepted.
  final PixKeyValidationError? error;

  /// The key without formatting characters, ready to be stored.
  final String normalized;

  const PixKeyValidation({required this.normalized, this.type, this.error});

  bool get isValid => error == null && type != null;
}

/// Local format checks for Pix keys.
///
/// The validator only inspects the text format. It never confirms that a key
/// exists or that it belongs to a given person: only the Pix infrastructure
/// can answer that.
class PixKeyValidator {
  const PixKeyValidator._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w.!#$%&*+/=?^`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$',
  );

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Digits and the separators used by phone numbers and documents.
  static final RegExp _numericFormPattern = RegExp(r'^[0-9+().\s/-]+$');

  /// Hexadecimal digits and hyphens, the alphabet of a random key.
  static final RegExp _randomKeyAttemptPattern = RegExp(r'^[0-9a-fA-F-]+$');

  /// Validates [input] and reports the detected key type.
  ///
  /// The order of the checks matters: a formatted CPF also carries hyphens, so
  /// the random key is recognised by its full UUID shape, never by a hyphen.
  static PixKeyValidation validate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const PixKeyValidation(
        normalized: '',
        error: PixKeyValidationError.empty,
      );
    }

    if (trimmed.contains('@')) {
      final valid = _emailPattern.hasMatch(trimmed);
      return PixKeyValidation(
        normalized: trimmed.toLowerCase(),
        type: PixKeyType.email,
        error: valid ? null : PixKeyValidationError.invalidEmail,
      );
    }

    if (_uuidPattern.hasMatch(trimmed)) {
      return PixKeyValidation(
        normalized: trimmed.toLowerCase(),
        type: PixKeyType.random,
      );
    }

    if (_numericFormPattern.hasMatch(trimmed)) {
      return _validateNumeric(trimmed);
    }

    // Hexadecimal digits and hyphens only: the user aimed at a random key.
    if (_randomKeyAttemptPattern.hasMatch(trimmed)) {
      return PixKeyValidation(
        normalized: trimmed.toLowerCase(),
        type: PixKeyType.random,
        error: PixKeyValidationError.invalidRandomKey,
      );
    }

    return PixKeyValidation(
      normalized: trimmed,
      error: PixKeyValidationError.unrecognized,
    );
  }

  /// Validates [input] against the key type the user picked.
  ///
  /// The send flow asks for the type before the key, so the message points at
  /// the chosen format instead of guessing what the user meant.
  static PixKeyValidation validateAs(PixKeyType type, String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const PixKeyValidation(
        normalized: '',
        error: PixKeyValidationError.empty,
      );
    }

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

    switch (type) {
      case PixKeyType.cpf:
        final valid = digits.length == 11 && CpfValidator.isValid(digits);
        return PixKeyValidation(
          normalized: valid ? digits : trimmed,
          type: type,
          error: valid ? null : PixKeyValidationError.invalidDocument,
        );
      case PixKeyType.cnpj:
        final valid = digits.length == 14 && CpfValidator.isValid(digits);
        return PixKeyValidation(
          normalized: valid ? digits : trimmed,
          type: type,
          error: valid ? null : PixKeyValidationError.invalidDocument,
        );
      case PixKeyType.phone:
        // A number typed without the country code is a Brazilian one, which is
        // what the field asks for.
        if (digits.length == 10 || digits.length == 11) {
          return PixKeyValidation(normalized: '+55$digits', type: type);
        }
        if (digits.length == 12 || digits.length == 13) {
          return PixKeyValidation(normalized: '+$digits', type: type);
        }
        return PixKeyValidation(
          normalized: trimmed,
          type: type,
          error: PixKeyValidationError.invalidPhone,
        );
      case PixKeyType.email:
        final valid = _emailPattern.hasMatch(trimmed);
        return PixKeyValidation(
          normalized: trimmed.toLowerCase(),
          type: type,
          error: valid ? null : PixKeyValidationError.invalidEmail,
        );
      case PixKeyType.random:
        final valid = _uuidPattern.hasMatch(trimmed);
        return PixKeyValidation(
          normalized: trimmed.toLowerCase(),
          type: type,
          error: valid ? null : PixKeyValidationError.invalidRandomKey,
        );
    }
  }

  /// Reads a key made of digits and separators: a phone number, a CPF or a
  /// CNPJ.
  static PixKeyValidation _validateNumeric(String trimmed) {
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

    // A phone key carries the country code, so it is longer than a CPF.
    if (trimmed.startsWith('+') || digits.length == 12 || digits.length == 13) {
      final valid = digits.length == 12 || digits.length == 13;
      return PixKeyValidation(
        normalized: valid ? '+$digits' : trimmed,
        type: PixKeyType.phone,
        error: valid ? null : PixKeyValidationError.invalidPhone,
      );
    }

    if (digits.length == 11) {
      final valid = CpfValidator.isValid(digits);
      return PixKeyValidation(
        normalized: digits,
        type: PixKeyType.cpf,
        error: valid ? null : PixKeyValidationError.invalidDocument,
      );
    }

    if (digits.length == 14) {
      final valid = CpfValidator.isValid(digits);
      return PixKeyValidation(
        normalized: digits,
        type: PixKeyType.cnpj,
        error: valid ? null : PixKeyValidationError.invalidDocument,
      );
    }

    if (digits.length == 10) {
      return PixKeyValidation(
        normalized: trimmed,
        type: PixKeyType.phone,
        error: PixKeyValidationError.invalidPhone,
      );
    }

    return PixKeyValidation(
      normalized: trimmed,
      error: PixKeyValidationError.unrecognized,
    );
  }
}
