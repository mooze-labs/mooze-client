import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

enum DepositStatus {
  pending,
  underReview,
  processing,
  fundsPrepared,
  depixSent,
  paid,
  broadcasted,
  finished,
  completed,
  failed,
  expired,
  refunded,
  med,
  processingRefund,
  broadcastedRefund,
  timeout,
  unknown;

  static DepositStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return DepositStatus.pending;
      case 'under_review':
        return DepositStatus.underReview;
      case 'processing':
        return DepositStatus.processing;
      case 'funds_prepared':
        return DepositStatus.fundsPrepared;
      case 'depix_sent':
        return DepositStatus.depixSent;
      case 'paid':
        return DepositStatus.paid;
      case 'broadcasted':
        return DepositStatus.broadcasted;
      case 'finished':
        return DepositStatus.finished;
      case 'completed':
        return DepositStatus.completed;
      case 'failed':
        return DepositStatus.failed;
      case 'expired':
        return DepositStatus.expired;
      case 'refunded':
        return DepositStatus.refunded;
      case 'med':
        return DepositStatus.med;
      case 'processing_refund':
        return DepositStatus.processingRefund;
      case 'broadcasted_refund':
        return DepositStatus.broadcastedRefund;
      case 'timeout':
        return DepositStatus.timeout;
      default:
        return DepositStatus.unknown;
    }
  }
}

extension DepositStatusExtension on DepositStatus {
  String localizedLabel(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (this) {
      case DepositStatus.pending:
        return t.pix_deposit_status_pending_label;
      case DepositStatus.underReview:
        return t.pix_deposit_status_under_review_label;
      case DepositStatus.processing:
        return t.pix_deposit_status_processing_1_2_label;
      case DepositStatus.fundsPrepared:
        return t.pix_deposit_status_processing_1_2_label;
      case DepositStatus.depixSent:
        return t.pix_deposit_status_under_analysis_label;
      case DepositStatus.paid:
        return t.pix_deposit_status_under_analysis_label;
      case DepositStatus.broadcasted:
        return t.pix_deposit_status_processing_2_2_label;
      case DepositStatus.finished:
        return t.pix_deposit_status_finished_label;
      case DepositStatus.failed:
        return t.pix_deposit_status_processing_1_2_label;
      case DepositStatus.expired:
        return t.pix_deposit_status_expired_label;
      case DepositStatus.refunded:
        return t.pix_deposit_status_refunded_label;
      case DepositStatus.med:
        return t.pix_deposit_status_med_label;
      case DepositStatus.processingRefund:
        return t.pix_deposit_status_processing_refund_1_2_label;
      case DepositStatus.broadcastedRefund:
        return t.pix_deposit_status_processing_refund_2_2_label;
      case DepositStatus.completed:
        return t.pix_deposit_status_completed_label;
      case DepositStatus.timeout:
        return t.pix_deposit_status_expired_label;
      case DepositStatus.unknown:
        return t.pix_deposit_status_unknown_label;
    }
  }

  String localizedLabelPlural(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (this) {
      case DepositStatus.pending:
        return t.pix_deposit_status_pending_plural;
      case DepositStatus.underReview:
        return t.pix_deposit_status_under_review_plural;
      case DepositStatus.processing:
        return t.pix_deposit_status_processing_plural;
      case DepositStatus.fundsPrepared:
        return t.pix_deposit_status_in_transit_plural;
      case DepositStatus.depixSent:
        return t.pix_deposit_status_under_analysis_plural;
      case DepositStatus.paid:
        return t.pix_deposit_status_under_analysis_plural;
      case DepositStatus.broadcasted:
        return t.pix_deposit_status_in_transit_plural;
      case DepositStatus.finished:
        return t.pix_deposit_status_finished_plural;
      case DepositStatus.failed:
        return t.pix_deposit_status_processing_plural;
      case DepositStatus.expired:
        return t.pix_deposit_status_expired_plural;
      case DepositStatus.refunded:
        return t.pix_deposit_status_refunded_plural;
      case DepositStatus.med:
        return t.pix_deposit_status_under_analysis_plural;
      case DepositStatus.processingRefund:
        return t.pix_deposit_status_processing_refunds_plural;
      case DepositStatus.broadcastedRefund:
        return t.pix_deposit_status_processing_refunds_plural;
      case DepositStatus.completed:
        return t.pix_deposit_status_completed_plural;
      case DepositStatus.timeout:
        return t.pix_deposit_status_expired_plural;
      case DepositStatus.unknown:
        return t.pix_deposit_status_processing_plural;
    }
  }

  String get toApiString {
    switch (this) {
      case DepositStatus.pending:
        return 'pending';
      case DepositStatus.underReview:
        return 'under_review';
      case DepositStatus.processing:
        return 'processing';
      case DepositStatus.fundsPrepared:
        return 'funds_prepared';
      case DepositStatus.depixSent:
        return 'depix_sent';
      case DepositStatus.paid:
        return 'paid';
      case DepositStatus.broadcasted:
        return 'broadcasted';
      case DepositStatus.finished:
        return 'finished';
      case DepositStatus.completed:
        return 'completed';
      case DepositStatus.failed:
        return 'failed';
      case DepositStatus.expired:
        return 'expired';
      case DepositStatus.refunded:
        return 'refunded';
      case DepositStatus.med:
        return 'med';
      case DepositStatus.processingRefund:
        return 'processing_refund';
      case DepositStatus.broadcastedRefund:
        return 'broadcasted_refund';
      case DepositStatus.timeout:
        return 'timeout';
      case DepositStatus.unknown:
        return 'unknown';
    }
  }

  Color get color {
    switch (this) {
      case DepositStatus.pending:
        return Colors.orange;
      case DepositStatus.underReview:
        return Colors.yellow;
      case DepositStatus.processing:
        return Colors.blue;
      case DepositStatus.fundsPrepared:
        return Colors.lightBlue;
      case DepositStatus.depixSent:
        return Colors.green;
      case DepositStatus.paid:
        return Colors.cyan;
      case DepositStatus.broadcasted:
        return Colors.teal;
      case DepositStatus.finished:
        return Colors.green;
      case DepositStatus.failed:
        return Colors.red;
      case DepositStatus.expired:
        return Colors.red;
      case DepositStatus.refunded:
        return Colors.amber;
      case DepositStatus.med:
        return Colors.purple;
      case DepositStatus.processingRefund:
        return Colors.orange;
      case DepositStatus.broadcastedRefund:
        return Colors.orange;
      case DepositStatus.completed:
        return Colors.green;
      case DepositStatus.timeout:
        return Colors.red;
      case DepositStatus.unknown:
        return Colors.grey;
    }
  }
}

class PixDeposit {
  final String depositId;
  final String pixKey;
  final Asset asset;
  final int amountInCents;
  final String network;
  final DepositStatus status;
  final DateTime createdAt;
  final String? blockchainTxid;
  final BigInt? assetAmount;

  PixDeposit({
    required this.depositId,
    required this.pixKey,
    required this.asset,
    required this.amountInCents,
    required this.network,
    required this.status,
    required this.createdAt,
    this.blockchainTxid,
    this.assetAmount,
  });
}
