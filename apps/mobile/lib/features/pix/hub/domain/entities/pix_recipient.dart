import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';

/// Someone who receives a Pix payment.
///
/// [maskedDocument] already arrives hidden, so no screen has to handle a full
/// document number.
class PixRecipient {
  final String id;
  final String name;

  /// Partially hidden CPF or CNPJ, as the Pix standard shows it.
  final String maskedDocument;

  /// Name of the institution that holds the account.
  final String institution;

  final PixKeyType keyType;

  /// The key used to reach this recipient.
  final String keyValue;

  /// When the user last paid this recipient, or null when never.
  final DateTime? lastPaidAt;

  const PixRecipient({
    required this.id,
    required this.name,
    required this.maskedDocument,
    required this.institution,
    required this.keyType,
    required this.keyValue,
    this.lastPaidAt,
  });

  /// Masked form of [keyValue], safe to show on screen.
  String get maskedKey => maskPixKey(keyType, keyValue);

  /// Up to two letters used by the avatar.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
