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
  failed,
  expired,
  unknown,
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
        return 'Finalizado';
      case DepositStatus.failed:
        return 'Falhou';
      case DepositStatus.expired:
        return 'Expirado';
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
      case DepositStatus.unknown:
        return 'Desconhecidos';
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
