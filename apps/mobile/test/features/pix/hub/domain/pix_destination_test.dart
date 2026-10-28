import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_destination.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_key_validator.dart';

import '../../../../shared/fake_core_sync_helpers.dart';
import '../check_digit_core_sync_helpers.dart';

void main() {
  useCoreSyncHelpers(const CheckDigitCoreSyncHelpers());

  PixDestination parse(String input) => PixDestinationParser.parse(input);

  test('an empty field is empty', () {
    expect(parse('   ').kind, PixDestinationKind.empty);
  });

  group('detects the key type', () {
    final cases = <String, (PixKeyType, String)>{
      'ana@exemplo.com.br': (PixKeyType.email, 'ana@exemplo.com.br'),
      '123e4567-e89b-12d3-a456-426614174000': (
        PixKeyType.random,
        '123e4567-e89b-12d3-a456-426614174000',
      ),
      '+55 11 99999-8888': (PixKeyType.phone, '+5511999998888'),
      '11.222.333/0001-81': (PixKeyType.cnpj, '11222333000181'),
      // A valid CPF with the 9, but 52 is not an area code.
      '529.982.247-25': (PixKeyType.cpf, '52998224725'),
      // A valid CPF without the 9 after the area code.
      '111.444.777-35': (PixKeyType.cpf, '11144477735'),
      // 11 digits, an invalid CPF with the mobile shape.
      '(11) 99999-8888': (PixKeyType.phone, '+5511999998888'),
    };
    cases.forEach((input, expected) {
      test(input, () {
        final destination = parse(input);
        expect(destination.kind, PixDestinationKind.key);
        expect(destination.isReady, isTrue);
        expect(destination.key!.type, expected.$1);
        expect(destination.key!.normalized, expected.$2);
      });
    });
  });

  test('a valid CPF with the mobile shape asks the user', () {
    // Area code 11, then 9: also passes the CPF check digits.
    const number = '11954736800';
    expect(PixKeyValidator.validateAs(PixKeyType.cpf, number).isValid, isTrue);

    final destination = parse(number);

    expect(destination.kind, PixDestinationKind.cpfOrPhone);
    expect(destination.isReady, isFalse);
    expect(destination.key!.type, PixKeyType.cpf);
    expect(destination.key!.normalized, number);
    expect(destination.phone!.type, PixKeyType.phone);
    expect(destination.phone!.normalized, '+55$number');
  });

  test('an invalid CPF without the mobile shape is an error', () {
    final destination = parse('111.444.777-30');

    expect(destination.kind, PixDestinationKind.invalid);
    expect(destination.key!.error, PixKeyValidationError.invalidDocument);
  });

  group('digits without the plus sign are a CPF, a mobile or a CNPJ', () {
    // A Pix phone key is a mobile number: 11 digits, or the country code
    // with a plus sign. Other lengths are incomplete.
    for (final input in ['(11) 3333-4444', '5511999998888', '1234567']) {
      test(input, () {
        final destination = parse(input);
        expect(destination.kind, PixDestinationKind.invalid);
        expect(destination.key!.error, PixKeyValidationError.unrecognized);
      });
    }
  });

  test('a text that matches no format is an error', () {
    final destination = parse('not a key');

    expect(destination.kind, PixDestinationKind.invalid);
    expect(destination.key!.error, PixKeyValidationError.unrecognized);
  });

  group('codes', () {
    final code = PixBrCodeParser.build(
      pixKey: 'ana@exemplo.com.br',
      merchantName: 'Padaria',
      merchantCity: 'Rio',
      amountInCents: 8450,
    );

    test('a pasted code is a code', () {
      final destination = parse(code);

      expect(destination.kind, PixDestinationKind.code);
      expect(destination.isReady, isTrue);
      expect(destination.code!.amountInCents, 8450);
    });

    test('a code with a wrong checksum is an error of the code', () {
      final broken = '${code.substring(0, code.length - 4)}0000';

      final destination = parse(broken);

      expect(destination.kind, PixDestinationKind.invalid);
      expect(destination.code!.error, PixBrCodeError.invalidChecksum);
    });
  });
}
