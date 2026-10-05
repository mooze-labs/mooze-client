import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/send_pix/presentation/widgets/clipboard_pix_key_suggestion.dart';

void main() {
  group('PixKeyDetector', () {
    test('accepts the supported key formats', () {
      expect(PixKeyDetector.looksLikePixKey('someone@example.com'), isTrue);
      expect(PixKeyDetector.looksLikePixKey('123.456.789-09'), isTrue); // CPF
      expect(PixKeyDetector.looksLikePixKey('12.345.678/0001-95'), isTrue); // CNPJ
      expect(PixKeyDetector.looksLikePixKey('+55 11 91234-5678'), isTrue);
      expect(
        PixKeyDetector.looksLikePixKey('123e4567-e89b-12d3-a456-426614174000'),
        isTrue,
      );
      expect(
        PixKeyDetector.looksLikePixKey('00020126580014br.gov.bcb.pix0136...'),
        isTrue,
      );
    });

    test('rejects ordinary clipboard text', () {
      expect(PixKeyDetector.looksLikePixKey(''), isFalse);
      expect(PixKeyDetector.looksLikePixKey('hello world'), isFalse);
      expect(PixKeyDetector.looksLikePixKey('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq'), isFalse);
      expect(PixKeyDetector.looksLikePixKey('1234'), isFalse);
    });
  });
}
