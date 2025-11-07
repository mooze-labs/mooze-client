import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';

void main() {
  group('SatsInputFormatter', () {
    late SatsInputFormatter formatter;

    setUp(() {
      formatter = SatsInputFormatter();
    });

    test('deve inicializar com 0', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: '');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '0');
    });

    test('digitar 1 deve resultar em 1', () {
      const oldValue = TextEditingValue(text: '0');
      const newValue = TextEditingValue(text: '1');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '1');
    });

    test('digitar 10 deve resultar em 10', () {
      const oldValue = TextEditingValue(text: '1');
      const newValue = TextEditingValue(text: '10');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '10');
    });

    test('digitar 100 deve resultar em 100', () {
      const oldValue = TextEditingValue(text: '10');
      const newValue = TextEditingValue(text: '100');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '100');
    });

    test('digitar 1000 deve resultar em 1.000', () {
      const oldValue = TextEditingValue(text: '100');
      const newValue = TextEditingValue(text: '1000');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '1.000');
    });

    test('digitar 10000 deve resultar em 10.000', () {
      const oldValue = TextEditingValue(text: '1.000');
      const newValue = TextEditingValue(text: '10000');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '10.000');
    });

    test('digitar 100000 deve resultar em 100.000', () {
      const oldValue = TextEditingValue(text: '10.000');
      const newValue = TextEditingValue(text: '100000');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '100.000');
    });

    test('digitar 1000000 deve resultar em 1.000.000', () {
      const oldValue = TextEditingValue(text: '100.000');
      const newValue = TextEditingValue(text: '1000000');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '1.000.000');
    });

    test('digitar 12345678 deve resultar em 12.345.678', () {
      const oldValue = TextEditingValue(text: '1.234.567');
      const newValue = TextEditingValue(text: '12345678');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '12.345.678');
    });

    test('deve remover zeros à esquerda corretamente', () {
      const oldValue = TextEditingValue(text: '0');
      const newValue = TextEditingValue(text: '00000123');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '123');
    });

    test('deve limitar a 10 dígitos', () {
      const oldValue = TextEditingValue(text: '9.999.999.999');
      const newValue = TextEditingValue(text: '99999999999');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '9.999.999.999');
    });

    test('parseValue deve converter texto formatado para int', () {
      expect(SatsInputFormatter.parseValue('1'), 1);
      expect(SatsInputFormatter.parseValue('10'), 10);
      expect(SatsInputFormatter.parseValue('100'), 100);
      expect(SatsInputFormatter.parseValue('1.000'), 1000);
      expect(SatsInputFormatter.parseValue('10.000'), 10000);
      expect(SatsInputFormatter.parseValue('100.000'), 100000);
      expect(SatsInputFormatter.parseValue('1.000.000'), 1000000);
      expect(SatsInputFormatter.parseValue('12.345.678'), 12345678);
    });

    test('formatValue deve formatar int para texto com separadores', () {
      expect(SatsInputFormatter.formatValue(0), '0');
      expect(SatsInputFormatter.formatValue(1), '1');
      expect(SatsInputFormatter.formatValue(10), '10');
      expect(SatsInputFormatter.formatValue(100), '100');
      expect(SatsInputFormatter.formatValue(1000), '1.000');
      expect(SatsInputFormatter.formatValue(10000), '10.000');
      expect(SatsInputFormatter.formatValue(100000), '100.000');
      expect(SatsInputFormatter.formatValue(1000000), '1.000.000');
      expect(SatsInputFormatter.formatValue(12345678), '12.345.678');
    });
  });
}
