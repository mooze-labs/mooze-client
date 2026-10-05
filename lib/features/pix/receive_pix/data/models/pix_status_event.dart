import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';

class PixStatusEvent {
  String depositId;
  DepositStatus status;
  String? blockchainTxid;
  int? assetAmount;
  String? errorMessage;

  PixStatusEvent({
    required this.depositId,
    required this.status,
    this.blockchainTxid,
    this.assetAmount,
    this.errorMessage,
  });
}
