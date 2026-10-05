import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/deep_links/pending_payment_link.dart';

void main() {
  tearDown(() => PendingPaymentLink.take());

  test('recognises payment schemes only', () {
    expect(PendingPaymentLink.isPaymentUri(Uri.parse('bitcoin:bc1qxyz')), isTrue);
    expect(
      PendingPaymentLink.isPaymentUri(Uri.parse('liquidnetwork:lq1abc')),
      isTrue,
    );
    expect(PendingPaymentLink.isPaymentUri(Uri.parse('/home')), isFalse);
    expect(PendingPaymentLink.isPaymentUri(Uri.parse('https://x.y')), isFalse);
  });

  test('rebuilds the bare wire form and strips a normalised leading slash', () {
    expect(
      PendingPaymentLink.toRaw(Uri.parse('bitcoin:/bc1qxyz?amount=0.01')),
      'bitcoin:bc1qxyz?amount=0.01',
    );
    expect(
      PendingPaymentLink.toRaw(Uri.parse('BITCOIN:bc1qxyz')),
      'bitcoin:bc1qxyz',
    );
  });

  test('capture stores and take clears', () {
    expect(PendingPaymentLink.tryCapture(Uri.parse('/unknown')), isFalse);
    expect(PendingPaymentLink.value.value, isNull);
    expect(PendingPaymentLink.tryCapture(Uri.parse('bitcoin:bc1qxyz')), isTrue);
    expect(PendingPaymentLink.take(), 'bitcoin:bc1qxyz');
    expect(PendingPaymentLink.take(), isNull);
  });
}
