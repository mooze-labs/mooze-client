import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_destination_input_formatter.dart';

import '../../../../shared/fake_core_sync_helpers.dart';
import '../check_digit_core_sync_helpers.dart';

final _formatter = PixDestinationInputFormatter();

/// Types [input] one character at a time, as a keyboard does.
TextEditingValue _type(String input, [TextEditingValue? start]) {
  var value = start ?? TextEditingValue.empty;
  for (final char in input.split('')) {
    final text = value.text + char;
    value = _formatter.formatEditUpdate(
      value,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }
  return value;
}

/// Presses backspace with the cursor at its current place.
TextEditingValue _backspace(TextEditingValue value) {
  final cursor = value.selection.end;
  final text =
      value.text.substring(0, cursor - 1) + value.text.substring(cursor);
  return _formatter.formatEditUpdate(
    value,
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor - 1),
    ),
  );
}

TextEditingValue _paste(String text) => _formatter.formatEditUpdate(
  TextEditingValue.empty,
  TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  ),
);

void main() {
  useCoreSyncHelpers(const CheckDigitCoreSyncHelpers());

  group('while typing digits', () {
    test('masks a CPF step by step', () {
      expect(_type('529').text, '529');
      expect(_type('5299').text, '529.9');
      expect(_type('5299822').text, '529.982.2');
      expect(_type('5299822472').text, '529.982.247-2');
      expect(_type('52998224725').text, '529.982.247-25');
    });

    test('masks 11 digits that read as a mobile as a phone', () {
      // An invalid CPF with an area code and a 9: a mobile number.
      expect(_type('11999998888').text, '(11) 99999-8888');
    });

    test('keeps the CPF mask for a number that is also a valid CPF', () {
      // The screen asks the user, and the CPF reading is the default.
      expect(_type('11954736800').text, '119.547.368-00');
    });

    test('masks a CNPJ from the 12th digit', () {
      expect(_type('112223330001').text, '11.222.333/0001');
      expect(_type('11222333000181').text, '11.222.333/0001-81');
    });

    test('ignores separators the user types', () {
      expect(_type('529.982.247-25').text, '529.982.247-25');
      expect(_type('(11) 99999-8888').text, '(11) 99999-8888');
    });
  });

  group('with the country code', () {
    test('masks a Brazilian mobile step by step', () {
      expect(_type('+').text, '+');
      expect(_type('+55').text, '+55');
      expect(_type('+5511').text, '+55 (11');
      expect(_type('+55119').text, '+55 (11) 9');
      expect(_type('+551199998888').text, '+55 (11) 9999-8888');
      expect(_type('+5511999998888').text, '+55 (11) 99999-8888');
    });

    test('keeps only the plus sign for another country', () {
      expect(_type('+14155550100').text, '+14155550100');
    });
  });

  group('editing', () {
    test('backspace removes digits and their separators', () {
      final cpf = _type('52998224725');
      final once = _backspace(cpf);
      expect(once.text, '529.982.247-2');
      // No trailing separator stays behind.
      expect(_backspace(once).text, '529.982.247');
    });

    test('backspace over a mask character removes the digit before it', () {
      // The cursor sits right after the hyphen.
      const cpf = TextEditingValue(
        text: '529.982.247-25',
        selection: TextSelection.collapsed(offset: 12),
      );

      final value = _backspace(cpf);

      expect(value.text, '529.982.242-5');
      expect(value.selection.end, 10);
    });

    test('deleting a digit of a phone goes back to the CPF mask', () {
      final phone = _type('11999998888');
      expect(_backspace(phone).text, '119.999.988-8');
    });

    test('a digit typed in the middle keeps the cursor after it', () {
      const start = TextEditingValue(
        text: '529.982.247',
        selection: TextSelection.collapsed(offset: 3),
      );
      final value = _formatter.formatEditUpdate(
        start,
        const TextEditingValue(
          text: '5291.982.247',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(value.text, '529.198.224-7');
      // The cursor stays right after the inserted "1".
      expect(value.selection.end, 5);
    });
  });

  group('text that is not a number', () {
    test('an email that starts with digits loses the mask', () {
      expect(_type('2023joao@exemplo.com').text, '2023joao@exemplo.com');
      expect(_type('1234@x.com').text, '1234@x.com');
    });

    test('an email stays as typed', () {
      expect(_type('ana@exemplo.com.br').text, 'ana@exemplo.com.br');
    });

    test('a random key typed by hand keeps its hyphens', () {
      const key = '12345678-1234-4234-a234-123456789012';
      expect(_type(key).text, key);
    });

    test('a pasted random key stays as pasted', () {
      const key = '123e4567-e89b-12d3-a456-426614174000';
      expect(_paste(key).text, key);
    });
  });

  group('paste', () {
    test('masks a pasted CPF and a pasted phone', () {
      expect(_paste('52998224725').text, '529.982.247-25');
      expect(_paste('+55 11 99999-8888').text, '+55 (11) 99999-8888');
    });

    test('leaves a pasted Pix code alone', () {
      const code = '00020126360014BR.GOV.BCB.PIX0114+5511999998888';
      expect(_paste(code).text, code);
    });
  });

  test('formatMobile', () {
    expect(
      PixDestinationInputFormatter.formatMobile('11954736800'),
      '(11) 95473-6800',
    );
  });
}
