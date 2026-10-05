import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Presentation-layer display mappings for transaction enums.
///
/// These switch/case translations (enum → icon, localized label, color, URL)
/// live here rather than on the domain entities so the wallet domain layer
/// stays free of Flutter and l10n dependencies, and the detail screen stays
/// focused on composition rather than mapping tables.

extension TransactionTypeDisplay on TransactionType {
  String label(AppLocalizations t) {
    switch (this) {
      case TransactionType.send:
        return t.tx_type_send;
      case TransactionType.receive:
        return t.tx_type_receive;
      case TransactionType.swap:
        return t.tx_type_swap;
      case TransactionType.redeposit:
        return t.tx_type_redeposit;
      case TransactionType.submarine:
        return t.tx_type_swap;
      case TransactionType.unknown:
        return t.tx_type_unknown;
    }
  }
}

extension TransactionStatusDisplay on TransactionStatus {
  /// Icon for the inline status chip in send/receive and detail rows.
  IconData get icon {
    switch (this) {
      case TransactionStatus.pending:
        return Icons.schedule;
      case TransactionStatus.confirmed:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.check_circle_outline;
      case TransactionStatus.refundable:
        return Icons.warning_amber_rounded;
    }
  }

  String label(AppLocalizations t) {
    switch (this) {
      case TransactionStatus.pending:
        return t.tx_status_pending;
      case TransactionStatus.confirmed:
        return t.tx_status_confirmed_fem;
      case TransactionStatus.failed:
        return t.tx_status_failed_processed;
      case TransactionStatus.refundable:
        return t.tx_status_refundable_pending;
    }
  }

  /// Icon for the large swap/refund header medallion — intentionally distinct
  /// from the inline [icon] used by the status chip.
  IconData get swapIcon {
    switch (this) {
      case TransactionStatus.confirmed:
        return Icons.check_circle_rounded;
      case TransactionStatus.pending:
        return Icons.schedule_rounded;
      case TransactionStatus.refundable:
        return Icons.warning_amber_rounded;
      case TransactionStatus.failed:
        return Icons.assignment_return_rounded;
    }
  }

  String swapLabel(AppLocalizations t) {
    switch (this) {
      case TransactionStatus.confirmed:
        return t.tx_detail_swap_completed;
      case TransactionStatus.pending:
        return t.tx_detail_swap_in_progress;
      case TransactionStatus.refundable:
        return t.tx_detail_swap_unfinished;
      case TransactionStatus.failed:
        return t.tx_detail_swap_refunded;
    }
  }
}

extension BlockchainDisplay on Blockchain {
  /// Full network label as shown in the "Blockchain" detail row
  /// (e.g. "Lightning Network", "Liquid Network").
  String get networkLabel {
    switch (this) {
      case Blockchain.bitcoin:
        return 'Bitcoin';
      case Blockchain.lightning:
        return 'Lightning Network';
      case Blockchain.liquid:
        return 'Liquid Network';
    }
  }

  /// Short network name used in action subtitles and id-row labels
  /// (e.g. "Lightning", "Liquid").
  String get shortName {
    switch (this) {
      case Blockchain.bitcoin:
        return 'Bitcoin';
      case Blockchain.liquid:
        return 'Liquid';
      case Blockchain.lightning:
        return 'Lightning';
    }
  }

  String explorerUrl(String txId) {
    return switch (this) {
      Blockchain.bitcoin => 'https://mempool.bitaroo.net/pt/tx/$txId',
      Blockchain.liquid => 'https://liquid.network/pt/tx/$txId',
      Blockchain.lightning => 'https://blockstream.info/liquid/tx/$txId',
    };
  }
}

/// Status color depends on both [Transaction.status] and [Transaction.type] —
/// a confirmed swap reads as positive regardless of the generic status color —
/// so it hangs off the transaction rather than the status alone.
extension TransactionStatusColor on Transaction {
  Color statusColor(BuildContext context) {
    final colors = context.colors;
    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    if (type == TransactionType.swap &&
        status == TransactionStatus.confirmed) {
      return colors.positiveColor;
    }

    switch (status) {
      case TransactionStatus.pending:
        return appColors.warning;
      case TransactionStatus.confirmed:
        return colors.positiveColor;
      case TransactionStatus.failed:
        return colorScheme.error;
      case TransactionStatus.refundable:
        return colorScheme.primary;
    }
  }
}
