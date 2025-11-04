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
  unknown,
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
