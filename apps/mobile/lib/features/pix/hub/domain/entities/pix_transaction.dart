import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_method.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';

/// Whether money enters or leaves the wallet.
enum PixTransactionDirection { incoming, outgoing }

/// Result of a Pix movement.
enum PixTransactionStatus { completed, pending, failed }

/// What kind of Pix movement the record holds.
enum PixTransactionKind {
  /// A payment sent to someone else.
  sent,

  /// A payment received from someone else.
  received,

  /// A deposit the user made into their own wallet.
  deposit,

  /// A payment received through a payment link.
  paymentLink,
}

/// One Pix movement in the history.
///
/// The hub never mixes these records with on-chain wallet transactions.
class PixTransaction {
  final String id;
  final PixTransactionKind kind;
  final PixTransactionStatus status;

  /// Name shown in the list: the recipient, the payer or the deposit label.
  final String counterpartyName;

  /// Amount in BRL cents. Always positive; [direction] carries the sign.
  final int amountInCents;

  final DateTime createdAt;

  /// Short note written by the payer, or null when there is none.
  final String? description;

  /// How the payment was started, for records the user created.
  final PixSendMethod? method;

  /// Id of the source record: the withdrawal or the deposit.
  final String reference;

  /// Status of the deposit behind a deposit row. [status] only sorts it into
  /// done, pending or failed. The row shows this one, as the deposit details.
  final DepositStatus? depositStatus;

  /// Last status read of the withdrawal behind a send row, or null before
  /// the first read. The row shows it, as the send result screen.
  final PixWithdrawalStatus? withdrawalStatus;

  const PixTransaction({
    required this.id,
    required this.kind,
    required this.status,
    required this.counterpartyName,
    required this.amountInCents,
    required this.createdAt,
    required this.reference,
    this.description,
    this.method,
    this.depositStatus,
    this.withdrawalStatus,
  });

  PixTransactionDirection get direction => kind == PixTransactionKind.sent
      ? PixTransactionDirection.outgoing
      : PixTransactionDirection.incoming;
}
