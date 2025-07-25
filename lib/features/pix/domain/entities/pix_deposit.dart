import 'package:mooze_mobile/shared/entities/asset.dart';

enum DepositStatus { pending, processing, finished, expired }

class PixDeposit {
  final String depositId;
  final Asset asset;
  final int amountInCents;
  final String network;
  final DepositStatus status;
  final String? blockchainTxid;
  final BigInt? assetAmount;

  PixDeposit({
    required this.depositId,
    required this.asset,
    required this.amountInCents,
    required this.network,
    required this.status,
    this.blockchainTxid,
    this.assetAmount,
  });
}
