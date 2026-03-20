import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

enum DepositStatus {
  pending,
  underReview,
  processing,
  fundsPrepared,
  depixSent,
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
      case 'paid':
        return DepositStatus.depixSent;
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
  String get label {
    switch (this) {
      case DepositStatus.pending:
        return 'Pendente';
      case DepositStatus.underReview:
        return 'Em Análise';
      case DepositStatus.processing:
        return 'Processando';
      case DepositStatus.fundsPrepared:
        return 'Fundos Preparados';
      case DepositStatus.depixSent:
        return 'Enviado';
      case DepositStatus.broadcasted:
        return 'Transmitido';
      case DepositStatus.finished:
        return 'Enviado';
      case DepositStatus.failed:
        return 'Em Análise';
      case DepositStatus.expired:
        return 'Expirado';
      case DepositStatus.refunded:
        return 'Reembolso efetuado';
      case DepositStatus.med:
        return 'Estornado';
      case DepositStatus.processingRefund:
        return 'Processando estorno';
      case DepositStatus.broadcastedRefund:
        return 'Processando estorno';
      case DepositStatus.completed:
        return 'Concluído';
      case DepositStatus.timeout:
        return 'Tempo esgotado';
      case DepositStatus.unknown:
        return 'Desconhecido';
    }
  }

  String get labelPlural {
    switch (this) {
      case DepositStatus.pending:
        return 'Pendentes';
      case DepositStatus.underReview:
        return 'Em Análise';
      case DepositStatus.processing:
        return 'Processando';
      case DepositStatus.fundsPrepared:
        return 'Fundos Preparados';
      case DepositStatus.depixSent:
        return 'Enviados';
      case DepositStatus.broadcasted:
        return 'Transmitidos';
      case DepositStatus.finished:
        return 'Finalizados';
      case DepositStatus.failed:
        return 'Falhados';
      case DepositStatus.expired:
        return 'Expirados';
      case DepositStatus.refunded:
        return 'Devolvidos';
      case DepositStatus.med:
        return 'Estornados';
      case DepositStatus.processingRefund:
        return 'Processando estorno';
      case DepositStatus.broadcastedRefund:
        return 'Processando estorno';
      case DepositStatus.completed:
        return 'Concluídos';
      case DepositStatus.timeout:
        return 'Tempo esgotado';
      case DepositStatus.unknown:
        return 'Desconhecidos';
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
