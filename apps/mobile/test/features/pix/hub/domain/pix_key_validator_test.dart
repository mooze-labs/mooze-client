import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_key_validator.dart';

import '../check_digit_core_sync_helpers.dart';
import '../../../../shared/fake_core_sync_helpers.dart';

void main() {
  useCoreSyncHelpers(const CheckDigitCoreSyncHelpers());

  group('PixKeyValidator', () {
    test('rejects an empty key', () {
      final result = PixKeyValidator.validate('   ');
      expect(result.isValid, isFalse);
      expect(result.error, PixKeyValidationError.empty);
    });

    test('accepts a valid CPF and strips the formatting', () {
      final result = PixKeyValidator.validate('529.982.247-25');
      expect(result.isValid, isTrue);
      expect(result.type, PixKeyType.cpf);
      expect(result.normalized, '52998224725');
    });

    test('rejects a CPF with wrong check digits', () {
      final result = PixKeyValidator.validate('529.982.247-24');
      expect(result.type, PixKeyType.cpf);
      expect(result.error, PixKeyValidationError.invalidDocument);
    });

    test('accepts a valid CNPJ', () {
      final result = PixKeyValidator.validate('11.222.333/0001-81');
      expect(result.isValid, isTrue);
      expect(result.type, PixKeyType.cnpj);
    });

    test('accepts a phone number with the country code', () {
      final result = PixKeyValidator.validate('+55 (11) 99999-0000');
      expect(result.isValid, isTrue);
      expect(result.type, PixKeyType.phone);
      expect(result.normalized, '+5511999990000');
    });

    test('rejects a phone number without the country code', () {
      final result = PixKeyValidator.validate('(11) 9999-0000');
      expect(result.type, PixKeyType.phone);
      expect(result.error, PixKeyValidationError.invalidPhone);
    });

    test('accepts an email and lowers its case', () {
      final result = PixKeyValidator.validate('Ana.Demo@Exemplo.Invalid');
      expect(result.isValid, isTrue);
      expect(result.type, PixKeyType.email);
      expect(result.normalized, 'ana.demo@exemplo.invalid');
    });

    test('rejects a malformed email', () {
      final result = PixKeyValidator.validate('ana.demo@exemplo');
      expect(result.error, PixKeyValidationError.invalidEmail);
    });

    test('accepts a random key in the UUID format', () {
      final result = PixKeyValidator.validate(
        '7b1f4c2e-5a3d-4c8b-9f10-2d6e8a4b7c91',
      );
      expect(result.isValid, isTrue);
      expect(result.type, PixKeyType.random);
    });

    test('rejects a random key with the wrong shape', () {
      final result = PixKeyValidator.validate('7b1f4c2e-5a3d-4c8b');
      expect(result.error, PixKeyValidationError.invalidRandomKey);
    });

    test('rejects free text', () {
      final result = PixKeyValidator.validate('pagar a ana');
      expect(result.error, PixKeyValidationError.unrecognized);
      expect(result.type, isNull);
    });
  });

  group('PixKeyValidator.validateAs', () {
    test('accepts a CPF typed under the CPF type', () {
      final result = PixKeyValidator.validateAs(
        PixKeyType.cpf,
        '529.982.247-25',
      );
      expect(result.isValid, isTrue);
      expect(result.normalized, '52998224725');
    });

    test('rejects a CNPJ typed under the CPF type', () {
      final result = PixKeyValidator.validateAs(
        PixKeyType.cpf,
        '11.222.333/0001-81',
      );
      expect(result.error, PixKeyValidationError.invalidDocument);
      expect(result.type, PixKeyType.cpf);
    });

    test('adds the country code to a national phone number', () {
      final result = PixKeyValidator.validateAs(
        PixKeyType.phone,
        '11 98765-4321',
      );
      expect(result.isValid, isTrue);
      expect(result.normalized, '+5511987654321');
    });

    test('keeps a phone number that already carries the country code', () {
      final result = PixKeyValidator.validateAs(
        PixKeyType.phone,
        '+55 11 98765-4321',
      );
      expect(result.isValid, isTrue);
      expect(result.normalized, '+5511987654321');
    });

    test('rejects a phone number with too few digits', () {
      final result = PixKeyValidator.validateAs(PixKeyType.phone, '98765');
      expect(result.error, PixKeyValidationError.invalidPhone);
    });

    test('rejects free text typed under the email type', () {
      final result = PixKeyValidator.validateAs(PixKeyType.email, 'ana demo');
      expect(result.error, PixKeyValidationError.invalidEmail);
    });

    test('accepts a random key under the random type', () {
      final result = PixKeyValidator.validateAs(
        PixKeyType.random,
        '7B1F4C2E-5A3D-4C8B-9F10-2D6E8A4B7C91',
      );
      expect(result.isValid, isTrue);
      expect(result.normalized, '7b1f4c2e-5a3d-4c8b-9f10-2d6e8a4b7c91');
    });

    test('reports an empty field for every type', () {
      for (final type in PixKeyType.values) {
        expect(
          PixKeyValidator.validateAs(type, '  ').error,
          PixKeyValidationError.empty,
        );
      }
    });
  });

  group('maskPixKey', () {
    test('hides the first and the last digits of a CPF', () {
      expect(maskPixKey(PixKeyType.cpf, '52998224725'), '***.982.247-**');
    });

    test('keeps only the last four digits of a phone number', () {
      expect(maskPixKey(PixKeyType.phone, '+5511999990000'), '(**) *****-0000');
    });

    test('keeps the first letter of an email', () {
      expect(
        maskPixKey(PixKeyType.email, 'ana@exemplo.invalid'),
        'a**@exemplo.invalid',
      );
    });

    test('shortens a random key', () {
      expect(
        maskPixKey(PixKeyType.random, '7b1f4c2e-5a3d-4c8b-9f10-2d6e8a4b7c91'),
        '7b1f4c2e…7c91',
      );
    });
  });
}
