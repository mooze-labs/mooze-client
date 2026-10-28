/// Whether a payment link is still waiting for a payment.
enum PixPaymentLinkStatus { pending, paid, expired }

/// A shareable charge created by the user.
///
/// The entity mirrors the fields of the `PaymentLink` schema used by the real
/// payment-link API, so a future integration can replace the demonstration
/// repository without changing the screens.
class PixPaymentLink {
  final String id;

  /// Public address the owner shares with the payer.
  final String url;

  /// Short text that identifies the charge for the owner.
  final String reference;

  /// Amount in BRL cents, or null when the payer informs the amount.
  final int? amountInCents;

  final PixPaymentLinkStatus status;
  final DateTime createdAt;

  /// When the payer settled the charge, or null while it is pending.
  final DateTime? paidAt;

  /// True when the link accepts a single payment only.
  final bool singleUse;

  const PixPaymentLink({
    required this.id,
    required this.url,
    required this.reference,
    required this.status,
    required this.createdAt,
    required this.singleUse,
    this.amountInCents,
    this.paidAt,
  });
}
