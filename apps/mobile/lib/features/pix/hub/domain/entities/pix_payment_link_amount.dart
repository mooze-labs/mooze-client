/// Amount bounds of a payment link with a fixed amount.
///
/// The bounds come from the `AmountPolicy` schema of the payment-link API:
/// `amount_in_cents` from 2000 to 500000, that is R$ 20,00 to R$ 5.000,00.
abstract final class PaymentLinkAmount {
  static const int minAmountInCents = 2000;
  static const int maxAmountInCents = 500000;
}

/// A fixed payment-link amount, in cents.
class FixedPaymentLinkAmount {
  final int amountInCents;

  const FixedPaymentLinkAmount(this.amountInCents);

  bool get isWithinBounds =>
      amountInCents >= PaymentLinkAmount.minAmountInCents &&
      amountInCents <= PaymentLinkAmount.maxAmountInCents;
}
