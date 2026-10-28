import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_method.dart';

/// A Pix payment the user is still composing.
///
/// The draft travels through the send flow screens until the amount step asks
/// the backend for a withdrawal. The backend pays a Pix key, so every method
/// ends in a key: a typed key, or the key inside a Pix code.
class PixSendDraft {
  final PixSendMethod method;
  final PixKeyType keyType;

  /// The normalized Pix key that receives the payout.
  final String pixKey;

  /// Digits of the CPF or CNPJ of the key owner, or null until the user types
  /// it. A CPF or CNPJ key is its own tax ID.
  final String? taxId;

  /// Payout in BRL cents: what the recipient receives. Zero while the user
  /// has not typed it yet.
  final int amountInCents;

  /// True when the source code already fixed the amount.
  final bool amountIsFixed;

  /// Merchant name read from the Pix code. The code states it; no service
  /// confirms it.
  final String? merchantName;

  /// The scanned or pasted code this draft came from, when there is one.
  final String? sourceCode;

  const PixSendDraft({
    required this.method,
    required this.keyType,
    required this.pixKey,
    this.taxId,
    this.amountInCents = 0,
    this.amountIsFixed = false,
    this.merchantName,
    this.sourceCode,
  });

  /// Builds the draft of a typed or scanned key. A CPF or CNPJ key fills the
  /// tax ID.
  factory PixSendDraft.forKey({
    required PixSendMethod method,
    required PixKeyType keyType,
    required String pixKey,
    int amountInCents = 0,
    bool amountIsFixed = false,
    String? merchantName,
    String? sourceCode,
  }) {
    final isDocument = keyType == PixKeyType.cpf || keyType == PixKeyType.cnpj;
    return PixSendDraft(
      method: method,
      keyType: keyType,
      pixKey: pixKey,
      taxId: isDocument ? pixKey.replaceAll(RegExp(r'[^0-9]'), '') : null,
      amountInCents: amountInCents,
      amountIsFixed: amountIsFixed,
      merchantName: merchantName,
      sourceCode: sourceCode,
    );
  }

  /// Lowest payout of `POST /withdraw`, in BRL cents.
  static const int minAmountInCents = 200;

  /// Highest payout of `POST /withdraw`, in BRL cents.
  static const int maxAmountInCents = 600000;

  bool get hasValidAmount =>
      amountInCents >= minAmountInCents && amountInCents <= maxAmountInCents;

  /// True when the user must type the tax ID of the key owner.
  bool get asksForTaxId =>
      keyType != PixKeyType.cpf && keyType != PixKeyType.cnpj;

  /// Masked form of [pixKey], safe to show on screen.
  String get maskedKey => maskPixKey(keyType, pixKey);

  PixSendDraft copyWith({int? amountInCents, String? taxId}) {
    return PixSendDraft(
      method: method,
      keyType: keyType,
      pixKey: pixKey,
      taxId: taxId ?? this.taxId,
      amountInCents: amountInCents ?? this.amountInCents,
      amountIsFixed: amountIsFixed,
      merchantName: merchantName,
      sourceCode: sourceCode,
    );
  }
}
