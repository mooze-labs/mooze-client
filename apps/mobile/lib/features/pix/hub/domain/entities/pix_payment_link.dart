import 'package:mooze_mobile/shared/entities/asset.dart';

/// Whether a payment link is still waiting for a payment.
enum PixPaymentLinkStatus {
  pending,
  paid,
  expired,

  /// The owner turned the link off. Payments already started still finish.
  revoked,
}

/// A shareable charge created by the user.
///
/// The entity mirrors the `OwnerPaymentLink` schema of the payment-link API.
class PixPaymentLink {
  final String id;

  /// Public address the owner shares with the payer.
  final String url;

  /// Short text that identifies the charge for the owner. The API has no
  /// such field, so the app keeps it on the device. It is empty for a link
  /// created elsewhere, for example by the merchant mode.
  final String reference;

  /// Amount in BRL cents, or null when the payer informs the amount.
  final int? amountInCents;

  /// Asset that the wallet receives, or null for an asset the app does not
  /// know.
  final Asset? asset;

  final PixPaymentLinkStatus status;
  final DateTime createdAt;

  /// When the payer settled the charge, or null while it is pending. The API
  /// does not return it today.
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
    this.asset,
    this.paidAt,
  });

  /// True while the link takes payments, so the owner can still revoke it.
  bool get isActive => status == PixPaymentLinkStatus.pending;

  PixPaymentLink withReference(String reference) => _copy(reference: reference);

  PixPaymentLink withStatus(PixPaymentLinkStatus status) =>
      _copy(status: status);

  PixPaymentLink _copy({String? reference, PixPaymentLinkStatus? status}) =>
      PixPaymentLink(
        id: id,
        url: url,
        reference: reference ?? this.reference,
        status: status ?? this.status,
        createdAt: createdAt,
        singleUse: singleUse,
        amountInCents: amountInCents,
        asset: asset,
        paidAt: paidAt,
      );
}
