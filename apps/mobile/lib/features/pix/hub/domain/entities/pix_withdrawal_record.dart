import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';

/// What the app knows about the DePix transfer that funds a withdrawal.
enum PixFundingStatus {
  /// The app started the broadcast and has no answer yet. A record left in
  /// this state means that the app stopped during the broadcast.
  attempting,

  /// The wallet broadcast the transfer.
  sent,

  /// The broadcast failed in a way that does not prove that nothing left the
  /// wallet. The user must not pay this withdrawal again.
  uncertain,

  /// The wallet stopped before the broadcast. No funds left the wallet.
  notSent,
}

/// Local record of a withdrawal that the app tried to fund.
///
/// The backend has no list endpoint, so this record is the only way to find
/// the withdrawal again after a restart. It keeps the masked key only: the
/// full Pix key and the tax ID are not stored.
class PixWithdrawalRecord {
  final String id;
  final DateTime createdAt;
  final int payoutAmountInCents;
  final int depositAmountInCents;
  final int depositAmountSats;
  final String depositAddress;
  final DateTime expiresAt;

  /// Masked Pix key of the recipient, safe to show on screen.
  final String maskedKey;

  final PixFundingStatus fundingStatus;

  /// Liquid transaction of the deposit, when the broadcast succeeded.
  final String? fundingTxid;

  /// Last status read from the backend, or null before the first read.
  final PixWithdrawalStatus? lastStatus;

  const PixWithdrawalRecord({
    required this.id,
    required this.createdAt,
    required this.payoutAmountInCents,
    required this.depositAmountInCents,
    required this.depositAmountSats,
    required this.depositAddress,
    required this.expiresAt,
    required this.maskedKey,
    required this.fundingStatus,
    this.fundingTxid,
    this.lastStatus,
  });

  /// Builds the record written before the broadcast.
  factory PixWithdrawalRecord.attempt(
    PixWithdrawal withdrawal, {
    required String maskedKey,
    required DateTime now,
  }) {
    return PixWithdrawalRecord(
      id: withdrawal.id,
      createdAt: now,
      payoutAmountInCents: withdrawal.payoutAmountInCents,
      depositAmountInCents: withdrawal.depositAmountInCents,
      depositAmountSats: withdrawal.depositAmountSats,
      depositAddress: withdrawal.depositAddress,
      expiresAt: withdrawal.expiresAt,
      maskedKey: maskedKey,
      fundingStatus: PixFundingStatus.attempting,
    );
  }

  /// Provider fee in BRL cents.
  int get feeInCents => depositAmountInCents - payoutAmountInCents;

  /// True while funds may have left the wallet and the backend has not
  /// reported a final status.
  bool get needsAttention =>
      fundingStatus != PixFundingStatus.notSent &&
      !(lastStatus?.isFinal ?? false);

  PixWithdrawalRecord copyWith({
    PixFundingStatus? fundingStatus,
    String? fundingTxid,
    PixWithdrawalStatus? lastStatus,
  }) {
    return PixWithdrawalRecord(
      id: id,
      createdAt: createdAt,
      payoutAmountInCents: payoutAmountInCents,
      depositAmountInCents: depositAmountInCents,
      depositAmountSats: depositAmountSats,
      depositAddress: depositAddress,
      expiresAt: expiresAt,
      maskedKey: maskedKey,
      fundingStatus: fundingStatus ?? this.fundingStatus,
      fundingTxid: fundingTxid ?? this.fundingTxid,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'created_at': createdAt.toUtc().toIso8601String(),
    'payout_amount_in_cents': payoutAmountInCents,
    'deposit_amount_in_cents': depositAmountInCents,
    'deposit_amount_sats': depositAmountSats,
    'deposit_address': depositAddress,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'masked_key': maskedKey,
    'funding_status': fundingStatus.name,
    'funding_txid': fundingTxid,
    'last_status': lastStatus?.name,
  };

  /// Reads a stored record. Returns null when a field is missing or has the
  /// wrong type.
  static PixWithdrawalRecord? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final createdAt = _date(json['created_at']);
    final payout = json['payout_amount_in_cents'];
    final deposit = json['deposit_amount_in_cents'];
    final sats = json['deposit_amount_sats'];
    final address = json['deposit_address'];
    final expiresAt = _date(json['expires_at']);
    final maskedKey = json['masked_key'];
    final funding = PixFundingStatus.values
        .where((s) => s.name == json['funding_status'])
        .firstOrNull;
    if (id is! String ||
        createdAt == null ||
        payout is! int ||
        deposit is! int ||
        sats is! int ||
        address is! String ||
        expiresAt == null ||
        maskedKey is! String ||
        funding == null) {
      return null;
    }
    final txid = json['funding_txid'];
    final lastStatus = json['last_status'];
    return PixWithdrawalRecord(
      id: id,
      createdAt: createdAt,
      payoutAmountInCents: payout,
      depositAmountInCents: deposit,
      depositAmountSats: sats,
      depositAddress: address,
      expiresAt: expiresAt,
      maskedKey: maskedKey,
      fundingStatus: funding,
      fundingTxid: txid is String ? txid : null,
      lastStatus: lastStatus is String
          ? PixWithdrawalStatus.parse(lastStatus)
          : null,
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
