import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';

/// Rows of the Pix history, built from the real records.
///
/// The backend lists neither the withdrawals nor the deposits of a user. The
/// sends come from the withdrawal records of the device, and the deposits
/// from the deposit store of mooze-core.

/// The history row of a send, or null when nothing left the wallet.
PixTransaction? pixTransactionFromWithdrawal(PixWithdrawalRecord record) {
  if (record.fundingStatus == PixFundingStatus.notSent) return null;
  final status = record.lastStatus;
  return PixTransaction(
    id: record.id,
    kind: PixTransactionKind.sent,
    status: status == null || !status.isFinal
        ? PixTransactionStatus.pending
        : status.isCompleted
        ? PixTransactionStatus.completed
        : PixTransactionStatus.failed,
    // The record keeps the masked key only, never the full key.
    counterpartyName: record.maskedKey,
    amountInCents: record.payoutAmountInCents,
    createdAt: record.createdAt,
    reference: record.id,
  );
}

/// The history row of a deposit into the user's own wallet.
PixTransaction pixTransactionFromDeposit(PixDeposit deposit) {
  return PixTransaction(
    id: deposit.depositId,
    kind: PixTransactionKind.deposit,
    status: switch (deposit.status) {
      DepositStatus.finished ||
      DepositStatus.completed => PixTransactionStatus.completed,
      // A refund or a return (MED) means that the deposit did not complete.
      DepositStatus.failed ||
      DepositStatus.expired ||
      DepositStatus.timeout ||
      DepositStatus.med ||
      DepositStatus.refunded ||
      DepositStatus.processingRefund ||
      DepositStatus.broadcastedRefund ||
      DepositStatus.finishedRefund => PixTransactionStatus.failed,
      _ => PixTransactionStatus.pending,
    },
    counterpartyName: deposit.asset.ticker,
    amountInCents: deposit.amountInCents,
    createdAt: deposit.createdAt,
    reference: deposit.depositId,
  );
}
