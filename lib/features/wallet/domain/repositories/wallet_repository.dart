import '../entities/transaction.dart';
import '../entities/payment_request.dart';
import '../entities/partially_signed_transaction.dart';
import '../entities/refundable_swap.dart';

import '../enums/asset.dart';
import '../enums/blockchain.dart';
import '../typedefs.dart';

abstract class WalletRepository {
  Future<List<Transaction>> getTransactions({
    TransactionType? type,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Balance> getBalance();
  Future<PaymentRequest> createInvoice(
    Asset asset,
    Blockchain blockchain,
    BigInt? amount,
    String? description,
  );
  Future<PartiallySignedTransaction> buildTransaction(
    String destination,
    Asset asset,
    BigInt amount,
    Blockchain blockchain,
  );
  Future<Transaction> sendPayment(PartiallySignedTransaction psbt);
  Future<int> getTransactionLimits(Blockchain blockchain);
  Future<RefundableSwap> listRefundableTransactions();
}
