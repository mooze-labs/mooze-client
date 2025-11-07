import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/formatters/btc_input_formatter.dart';

void main() {
  group('BtcInputFormatter', () {
    late BtcInputFormatter formatter;

    setUp(() {
      formatter = BtcInputFormatter();
    });

    test('deve inicializar com 0.00000000', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: '');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '0.00000000');
    });

    test('digitar 1 deve resultar em 0.00000001', () {
      const oldValue = TextEditingValue(text: '0.00000000');
      const newValue = TextEditingValue(text: '1');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '0.00000001');
    });

    test('digitar 1 e depois 2 deve resultar em 0.00000012', () {
      const oldValue = TextEditingValue(text: '0.00000001');
      const newValue = TextEditingValue(text: '12');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '0.00000012');
    });

    test('digitar 1, 2, 3, 4, 5, 6, 7, 8 deve resultar em 0.12345678', () {
      const oldValue = TextEditingValue(text: '0.01234567');
      const newValue = TextEditingValue(text: '12345678');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '0.12345678');
    });

    test('digitar 9 dígitos deve resultar em 1.23456789', () {
      const oldValue = TextEditingValue(text: '0.12345678');
      const newValue = TextEditingValue(text: '123456789');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '1.23456789');
    });

    test('digitar 10 dígitos deve resultar em 12.34567890', () {
      const oldValue = TextEditingValue(text: '1.23456789');
      const newValue = TextEditingValue(text: '1234567890');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '12.34567890');
    });

    test('digitar 11 dígitos deve resultar em 123.45678901', () {
      const oldValue = TextEditingValue(text: '12.34567890');
      const newValue = TextEditingValue(text: '12345678901');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '123.45678901');
    });

    test('deve permitir valores grandes como 99999999.99999999', () {
      const oldValue = TextEditingValue(text: '9999999.99999999');
      const newValue = TextEditingValue(text: '9999999999999999');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '99999999.99999999');
    });

    test('não deve permitir mais de 16 dígitos', () {
      const oldValue = TextEditingValue(text: '99999999.99999999');
      const newValue = TextEditingValue(
        text: '99999999999999999',
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '99999999.99999999');
    });

    test('deve remover zeros à esquerda corretamente', () {
      const oldValue = TextEditingValue(text: '0.00000000');
      const newValue = TextEditingValue(text: '00000123');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '0.00000123');
    });

    test('parseValue deve funcionar com valores pequenos', () {
      expect(BtcInputFormatter.parseValue('0.00000001'), 0.00000001);
      expect(BtcInputFormatter.parseValue('0.00000123'), 0.00000123);
      expect(BtcInputFormatter.parseValue('0.12345678'), 0.12345678);
    });

    test('parseValue deve funcionar com valores maiores que 1', () {
      expect(BtcInputFormatter.parseValue('1.00000000'), 1.0);
      expect(BtcInputFormatter.parseValue('1.23456789'), 1.23456789);
      expect(BtcInputFormatter.parseValue('12.34567890'), 12.34567890);
      expect(BtcInputFormatter.parseValue('123.45678901'), 123.45678901);
    });

    test('formatValue deve funcionar com valores pequenos', () {
      expect(BtcInputFormatter.formatValue(0.00000001), '0.00000001');
      expect(BtcInputFormatter.formatValue(0.00000123), '0.00000123');
      expect(BtcInputFormatter.formatValue(0.12345678), '0.12345678');
    });

    test('formatValue deve funcionar com valores maiores que 1', () {
      expect(BtcInputFormatter.formatValue(1.0), '1.00000000');
      expect(BtcInputFormatter.formatValue(1.23456789), '1.23456789');
      expect(BtcInputFormatter.formatValue(12.3456789), '12.34567890');
      expect(BtcInputFormatter.formatValue(123.45678901), '123.45678901');
    });
  });
}
