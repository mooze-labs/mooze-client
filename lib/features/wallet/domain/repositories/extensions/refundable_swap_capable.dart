import '../../entities/refundable_swap.dart';

abstract class RefundableSwapCapable {
  Future<RefundableSwap> listRefundableTransactions();
}
