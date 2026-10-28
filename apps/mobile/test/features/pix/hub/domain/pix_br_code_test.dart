import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';

void main() {
  group('PixBrCodeParser.crc16', () {
    test('matches the check value of CRC-16/CCITT-FALSE', () {
      // The standard check value of the algorithm the BR Code uses.
      expect(PixBrCodeParser.crc16('123456789'), '29B1');
    });

    test('changes when the payload changes', () {
      expect(
        PixBrCodeParser.crc16('5802BR6304'),
        isNot(PixBrCodeParser.crc16('5802AR6304')),
      );
    });
  });

  group('PixBrCodeParser.build', () {
    test('produces a payload that parses back', () {
      final code = PixBrCodeParser.build(
        pixKey: 'ana.demo@exemplo.invalid',
        merchantName: 'Mooze Demonstração',
        merchantCity: 'São Paulo',
        amountInCents: 8450,
        transactionId: 'DEMO123',
      );

      final parsed = PixBrCodeParser.parse(code);
      expect(parsed.isStructurallyValid, isTrue);
      expect(parsed.pixKey, 'ana.demo@exemplo.invalid');
      expect(parsed.amountInCents, 8450);
      expect(parsed.merchantName, 'MOOZE DEMONSTRACAO');
      expect(parsed.merchantCity, 'SAO PAULO');
      expect(parsed.transactionId, 'DEMO123');
      expect(parsed.hasOpenAmount, isFalse);
    });

    test('leaves the amount open when none is supplied', () {
      final code = PixBrCodeParser.build(
        pixKey: 'ana.demo@exemplo.invalid',
        merchantName: 'MOOZE DEMO',
        merchantCity: 'SAO PAULO',
      );

      final parsed = PixBrCodeParser.parse(code);
      expect(parsed.isStructurallyValid, isTrue);
      expect(parsed.hasOpenAmount, isTrue);
    });
  });

  group('PixBrCodeParser.parse', () {
    test('reports an empty code', () {
      expect(PixBrCodeParser.parse('  ').error, PixBrCodeError.empty);
    });

    test('reports a short code', () {
      expect(
        PixBrCodeParser.parse('0002010102').error,
        PixBrCodeError.tooShort,
      );
    });

    test('reports a malformed code', () {
      expect(
        PixBrCodeParser.parse(
          'this text is long enough but has no fields at all',
        ).error,
        PixBrCodeError.malformed,
      );
    });

    test('reports a code without the Pix merchant account', () {
      const payload =
          '00020126330014BR.GOV.XXX.YYY0111123456789015204000053039865802BR'
          '5913Fulano de Tal6008BRASILIA62070503***6304';
      final code = '$payload${PixBrCodeParser.crc16(payload)}';
      expect(PixBrCodeParser.parse(code).error, PixBrCodeError.notPix);
    });

    test('reports a wrong checksum', () {
      final code = PixBrCodeParser.build(
        pixKey: 'ana.demo@exemplo.invalid',
        merchantName: 'MOOZE DEMO',
        merchantCity: 'SAO PAULO',
      );
      final tampered = '${code.substring(0, code.length - 4)}0000';
      expect(
        PixBrCodeParser.parse(tampered).error,
        PixBrCodeError.invalidChecksum,
      );
    });

    test('ignores the whitespace around a pasted code', () {
      final code = PixBrCodeParser.build(
        pixKey: 'ana.demo@exemplo.invalid',
        merchantName: 'MOOZE DEMO',
        merchantCity: 'SAO PAULO',
        amountInCents: 1000,
      );
      final parsed = PixBrCodeParser.parse('  $code \n');
      expect(parsed.isStructurallyValid, isTrue);
      expect(parsed.amountInCents, 1000);
    });
  });
}
