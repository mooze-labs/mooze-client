import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';

void main() {
  group('CpfValidator.strip', () {
    test('removes mask characters, keeping only digits', () {
      expect(CpfValidator.strip('529.982.247-25'), '52998224725');
      expect(CpfValidator.strip('  529 982 247 25 '), '52998224725');
      expect(CpfValidator.strip('abc'), '');
    });
  });

  group('CpfValidator.validate', () {
    test('accepts valid CPFs (masked or raw)', () {
      // Well-known valid test CPFs.
      expect(CpfValidator.validate('529.982.247-25'), isNull);
      expect(CpfValidator.validate('52998224725'), isNull);
      expect(CpfValidator.validate('111.444.777-35'), isNull);
    });

    test('flags an empty field', () {
      expect(CpfValidator.validate(''), CpfValidationError.empty);
      expect(CpfValidator.validate('   '), CpfValidationError.empty);
    });

    test('flags fewer than 11 digits as incomplete', () {
      expect(CpfValidator.validate('529.982.247'), CpfValidationError.incomplete);
      expect(CpfValidator.validate('5299822472'), CpfValidationError.incomplete);
    });

    test('rejects repeated-digit sequences', () {
      expect(CpfValidator.validate('000.000.000-00'), CpfValidationError.invalid);
      expect(CpfValidator.validate('111.111.111-11'), CpfValidationError.invalid);
      expect(CpfValidator.validate('99999999999'), CpfValidationError.invalid);
    });

    test('rejects bad check digits', () {
      expect(CpfValidator.validate('529.982.247-26'), CpfValidationError.invalid);
      expect(CpfValidator.validate('111.444.777-30'), CpfValidationError.invalid);
    });
  });

  group('CpfValidator.validate (CNPJ)', () {
    test('accepts valid CNPJs (masked or raw)', () {
      expect(CpfValidator.validate('11.222.333/0001-81'), isNull);
      expect(CpfValidator.validate('11222333000181'), isNull);
    });

    test('rejects bad CNPJ check digits', () {
      expect(
        CpfValidator.validate('11222333000180'),
        CpfValidationError.invalid,
      );
    });

    test('rejects repeated-digit CNPJ', () {
      expect(
        CpfValidator.validate('00000000000000'),
        CpfValidationError.invalid,
      );
    });

    test('treats 12-13 digits as incomplete', () {
      expect(CpfValidator.validate('112223330001'), CpfValidationError.incomplete);
      expect(CpfValidator.validate('1122233300018'), CpfValidationError.incomplete);
    });
  });

  group('formatCpfCnpj', () {
    test('formats CPF and CNPJ', () {
      expect(formatCpfCnpj('52998224725'), '529.982.247-25');
      expect(formatCpfCnpj('11222333000181'), '11.222.333/0001-81');
    });
  });

  group('CpfValidator.isValid', () {
    test('mirrors validate()', () {
      expect(CpfValidator.isValid('529.982.247-25'), isTrue);
      expect(CpfValidator.isValid('529.982.247-26'), isFalse);
      expect(CpfValidator.isValid('11222333000181'), isTrue);
      expect(CpfValidator.isValid(''), isFalse);
    });
  });
}
