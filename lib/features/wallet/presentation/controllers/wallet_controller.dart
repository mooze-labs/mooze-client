import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';
import 'package:mooze_mobile/features/wallet/data/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/core/entities/asset.dart';

part 'wallet_controller.g.dart';

@riverpod
class WalletScreenController extends _$WalletScreenController {
  @override
  FutureOr<void> build() async {
    // Initialize the controller
  }

  /// Get the wallet repository instance
  WalletRepository get _repository => ref.read(walletRepositoryProvider);

  /// Get wallet balance
  Future<Balance> getBalance() async {
    return await _repository.getBalance();
  }

  /// Get transactions with optional filters
  Future<List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getTransactions(
      type: type,
      status: status,
      asset: asset,
      blockchain: blockchain,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Create a payment invoice
  Future<PaymentRequest> createInvoice(
    Asset asset,
    Blockchain blockchain,
    BigInt? amount,
    String? description,
  ) async {
    return await _repository.createInvoice(
      asset,
      blockchain,
      amount,
      description,
    );
  }

  /// Build a transaction
  Future<PartiallySignedTransaction> buildTransaction(
    String destination,
    Asset asset,
    BigInt amount,
    Blockchain blockchain,
  ) async {
    return await _repository.buildTransaction(
      destination,
      asset,
      amount,
      blockchain,
    );
  }

  /// Send a payment
  Future<Transaction> sendPayment(PartiallySignedTransaction psbt) async {
    return await _repository.sendPayment(psbt);
  }
}
