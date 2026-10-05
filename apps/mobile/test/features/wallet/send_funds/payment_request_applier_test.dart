import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/payment_request_applier.dart';

void main() {
  group('PaymentRequestApplier.displayAddress', () {
    test('strips BIP21 scheme and query', () {
      expect(
        PaymentRequestApplier.displayAddress('bitcoin:bc1qxyz?amount=0.5&label=x'),
        'bc1qxyz',
      );
      expect(
        PaymentRequestApplier.displayAddress('liquidnetwork:lq1abc?assetid=1'),
        'lq1abc',
      );
    });

    test('leaves plain addresses untouched', () {
      expect(PaymentRequestApplier.displayAddress('bc1qxyz'), 'bc1qxyz');
      expect(PaymentRequestApplier.displayAddress(''), '');
    });
  });
}
