import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';

extension TransactionFeeX on Transaction {
  BigInt? get totalFeeSat {
    final fee = feesSat;
    if (fee == null || fee <= BigInt.zero) return null;
    return fee;
  }

  bool get hasDisplayableFee => totalFeeSat != null;
}
