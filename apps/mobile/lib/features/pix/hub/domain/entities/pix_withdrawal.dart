/// Status of a Pix withdrawal, as `GET /withdraw/status` reports it.
///
/// The values come from the `WithdrawDetails.status` enum of the OpenAPI
/// document of the Mooze Engine.
enum PixWithdrawalStatus {
  /// The backend is creating the withdrawal at the provider. Local only.
  creating,

  /// The provider refused the withdrawal. Local only and final.
  rejected,

  /// The backend does not know if the provider created it. Local only.
  uncertain,

  /// The provider waits for the DePix deposit.
  unsent,

  /// The provider is sending the Pix.
  sending,

  /// The recipient received the Pix. Final.
  sent,

  /// The provider reported an error. The status can still change.
  error,

  /// The provider canceled the withdrawal. Final.
  canceled,

  /// The provider returned the deposit to the refund address. Final.
  refunded,

  /// The provider replaced the withdrawal. Final.
  replaced,

  /// The provider status is unknown, or the app does not know the value.
  unknown;

  /// Reads a status value. An unknown value maps to [unknown], which is not
  /// final, so the app never reports a settlement it cannot read.
  static PixWithdrawalStatus parse(Object? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return unknown;
  }

  /// True for the statuses that the OpenAPI document marks as final.
  bool get isFinal => switch (this) {
    sent || canceled || refunded || replaced || rejected => true,
    _ => false,
  };

  /// True only for [sent], the single status that proves the payout.
  bool get isCompleted => this == sent;
}

/// A withdrawal created by `POST /withdraw`.
///
/// It holds the funding instructions. The backend does not move funds: the
/// wallet sends [depositAmountSats] of DePix to [depositAddress] before
/// [fundingDeadline].
class PixWithdrawal {
  /// DePix base units in one BRL cent. DePix has 8 decimals and 1 DePix is
  /// 1 BRL, so `deposit_amount_sats = deposit_amount_in_cents × 1,000,000`.
  static const int depixUnitsPerCent = 1000000;

  /// Withdrawal ID for `GET /withdraw/status`.
  final String id;

  /// Withdrawal ID at the provider (Eulen).
  final String providerId;

  /// Liquid address that receives the DePix deposit.
  final String depositAddress;

  /// Asset ID that the deposit must use. Always the DePix asset.
  final String assetId;

  /// BRL amount that the deposit funds: the payout plus the provider fee.
  final int depositAmountInCents;

  /// Exact DePix amount to send, in base units.
  final int depositAmountSats;

  /// BRL amount that the recipient receives.
  final int payoutAmountInCents;

  /// Funding deadline, as the server states it.
  final DateTime expiresAt;

  /// [expiresAt] on the device clock. The repository corrects it with the
  /// server `Date` header, so a wrong device clock does not move it.
  final DateTime fundingDeadline;

  const PixWithdrawal({
    required this.id,
    required this.providerId,
    required this.depositAddress,
    required this.assetId,
    required this.depositAmountInCents,
    required this.depositAmountSats,
    required this.payoutAmountInCents,
    required this.expiresAt,
    required this.fundingDeadline,
  });

  /// Provider fee in BRL cents.
  int get feeInCents => depositAmountInCents - payoutAmountInCents;
}

/// Refund data of a withdrawal, when the provider returned the deposit.
class PixWithdrawalRefund {
  final String? reason;

  /// Liquid transaction that returned the funds.
  final String? txId;

  final int? feeInCents;

  /// BRL amount returned, after the refund fee.
  final int? netAmountInCents;

  const PixWithdrawalRefund({
    this.reason,
    this.txId,
    this.feeInCents,
    this.netAmountInCents,
  });
}

/// One item of `GET /withdraw/status`.
///
/// The response also carries the full Pix key. The app does not read it: the
/// screens show the masked key of the local record.
class PixWithdrawalDetails {
  final String id;
  final PixWithdrawalStatus status;
  final int? depositAmountInCents;
  final int? payoutAmountInCents;
  final DateTime? expiresAt;

  /// Liquid transaction that funded the withdrawal, as the backend sees it.
  final String? blockchainTxid;

  /// Receipt page of the provider.
  final String? receiptUrl;

  final String? receiverName;

  /// Tax number of the recipient, masked by the provider.
  final String? receiverTaxNumber;

  final DateTime? transferDate;

  /// End-to-end ID of the Pix at the Central Bank.
  final String? centralBankId;

  final PixWithdrawalRefund? refund;
  final DateTime createdAt;

  const PixWithdrawalDetails({
    required this.id,
    required this.status,
    required this.createdAt,
    this.depositAmountInCents,
    this.payoutAmountInCents,
    this.expiresAt,
    this.blockchainTxid,
    this.receiptUrl,
    this.receiverName,
    this.receiverTaxNumber,
    this.transferDate,
    this.centralBankId,
    this.refund,
  });
}
