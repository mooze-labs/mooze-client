import '../typedefs.dart';

class RefundableSwap {
  final Address swapAddress;
  final DateTime timestamp;
  final int amount;
  final String? lastRefundTxId;

  RefundableSwap({
    required this.swapAddress,
    required this.timestamp,
    required this.amount,
    this.lastRefundTxId,
  });
}
