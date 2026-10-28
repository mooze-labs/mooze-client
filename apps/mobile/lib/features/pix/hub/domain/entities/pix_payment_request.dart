import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';

/// A charge the user created so somebody else can pay them.
///
/// The hub produces these records in demonstration mode only: no charge is
/// registered with any Pix provider.
class PixPaymentRequest {
  final String id;

  /// Amount in BRL cents, or null when the payer informs the amount.
  final int? amountInCents;

  final String? description;

  /// The key the charge points to.
  final PixKey key;

  /// Copy and Paste payload that the QR Code encodes.
  final String brCode;

  final DateTime createdAt;

  /// When the charge stops accepting a payment.
  final DateTime expiresAt;

  const PixPaymentRequest({
    required this.id,
    required this.key,
    required this.brCode,
    required this.createdAt,
    required this.expiresAt,
    this.amountInCents,
    this.description,
  });

  /// Lowest charge accepted by the demonstration flow, in BRL cents.
  static const int minAmountInCents = 100;

  /// Highest charge accepted by the demonstration flow, in BRL cents.
  static const int maxAmountInCents = 2000000;
}
