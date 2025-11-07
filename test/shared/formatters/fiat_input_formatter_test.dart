import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';

void main() {
  group('FiatInputFormatter', () {
    late FiatInputFormatter formatter;

    setUp(() {
      formatter = FiatInputFormatter();
    });

    test('deve inicializar com 0,00', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: '');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '0,00');
    });

    test('digitar 1 deve resultar em 0,01', () {
      const oldValue = TextEditingValue(text: '0,00');
      const newValue = TextEditingValue(text: '1');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '0,01');
    });

    test('digitar 1 e depois 2 deve resultar em 0,12', () {
      const oldValue = TextEditingValue(text: '0,01');
      const newValue = TextEditingValue(text: '12');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '0,12');
    });

    test('digitar 1, 2, 3 deve resultar em 1,23', () {
      const oldValue = TextEditingValue(text: '0,12');
      const newValue = TextEditingValue(text: '123');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '1,23');
    });

    test('digitar 1, 2, 3, 4 deve resultar em 12,34', () {
      const oldValue = TextEditingValue(text: '1,23');
      const newValue = TextEditingValue(text: '1234');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '12,34');
    });

    test('digitar 1, 2, 3, 4, 5 deve resultar em 123,45', () {
      const oldValue = TextEditingValue(text: '12,34');
      const newValue = TextEditingValue(text: '12345');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '123,45');
    });

    test('deve adicionar separador de milhares em 1000', () {
      const oldValue = TextEditingValue(text: '999,99');
      const newValue = TextEditingValue(text: '100000');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '1.000,00');
    });

    test('deve adicionar separador de milhares em 1.234,56', () {
      const oldValue = TextEditingValue(text: '123,45');
      const newValue = TextEditingValue(text: '123456');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '1.234,56');
    });

    test('deve formatar 1 milhão corretamente', () {
      const oldValue = TextEditingValue(text: '99.999,99');
      const newValue = TextEditingValue(text: '100000000');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '1.000.000,00');
    });

    test('deve remover zeros à esquerda corretamente', () {
      const oldValue = TextEditingValue(text: '0,00');
      const newValue = TextEditingValue(text: '00000123');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '1,23');
    });

    test('parseValue deve converter texto formatado para double', () {
      expect(FiatInputFormatter.parseValue('0,01'), 0.01);
      expect(FiatInputFormatter.parseValue('1,23'), 1.23);
      expect(FiatInputFormatter.parseValue('12,34'), 12.34);
      expect(FiatInputFormatter.parseValue('123,45'), 123.45);
      expect(FiatInputFormatter.parseValue('1.234,56'), 1234.56);
      expect(FiatInputFormatter.parseValue('1.000,00'), 1000.00);
      expect(FiatInputFormatter.parseValue('1.000.000,00'), 1000000.00);
    });

    test('formatValue deve formatar double para texto', () {
      expect(FiatInputFormatter.formatValue(0.01), '0,01');
      expect(FiatInputFormatter.formatValue(1.23), '1,23');
      expect(FiatInputFormatter.formatValue(12.34), '12,34');
      expect(FiatInputFormatter.formatValue(123.45), '123,45');
      expect(FiatInputFormatter.formatValue(1234.56), '1.234,56');
      expect(FiatInputFormatter.formatValue(1000.00), '1.000,00');
      expect(FiatInputFormatter.formatValue(1000000.00), '1.000.000,00');
    });
  });
}
