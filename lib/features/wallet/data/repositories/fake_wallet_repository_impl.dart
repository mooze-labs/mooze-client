import 'package:mooze_mobile/core/entities/asset.dart';

import '../../domain/entities.dart';
import '../../domain/repositories/wallet_repository.dart';

class FakeWalletRepositoryImpl extends WalletRepository {
  // Mock data for testing
  final Map<String, dynamic> _mockData;

  FakeWalletRepositoryImpl({Map<String, dynamic>? mockData})
    : _mockData = mockData ?? {};

  @override
  Future<List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Return mock transactions
    final mockTransactions =
        _mockData['transactions'] as List<Transaction>? ??
        [
          Transaction(
            id: 'tx-001',
            amount: BigInt.from(1000000), // 0.01 BTC
            blockchain: Blockchain.bitcoin,
            asset: Asset.btc,
            type: TransactionType.receive,
            status: TransactionStatus.confirmed,
          ),
          Transaction(
            id: 'tx-002',
            amount: BigInt.from(500000), // 0.005 BTC
            blockchain: Blockchain.liquid,
            asset: Asset.depix,
            type: TransactionType.send,
            status: TransactionStatus.pending,
          ),
          Transaction(
            id: 'tx-003',
            amount: BigInt.from(10000000), // 0.1 BTC
            blockchain: Blockchain.bitcoin,
            asset: Asset.btc,
            type: TransactionType.swap,
            status: TransactionStatus.confirmed,
          ),
        ];

    // Apply filters if provided
    return mockTransactions.where((tx) {
      if (type != null && tx.type != type) return false;
      if (status != null && tx.status != status) return false;
      if (asset != null && tx.asset != asset) return false;
      if (blockchain != null && tx.blockchain != blockchain) return false;
      return true;
    }).toList();
  }

  @override
  Future<Balance> getBalance() async {
    // Return mock balance
    final mockBalance =
        _mockData['balance'] as Map<Asset, BigInt>? ??
        {
          Asset.btc: BigInt.from(50000000), // 0.5 BTC
          Asset.depix: BigInt.from(1000000000), // 10 DEPIX
          Asset.usdt: BigInt.from(50000000), // 50 USDT (assuming 6 decimals)
        };

    return mockBalance;
  }

  @override
  Future<PaymentRequest> createInvoice(
    Asset asset,
    Blockchain blockchain,
    BigInt? amount,
    String? description,
  ) async {
    // Return mock payment request
    final mockPaymentRequest =
        _mockData['paymentRequest'] as PaymentRequest? ??
        PaymentRequest(
          address: 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
          blockchain: blockchain,
          asset: asset,
          fees: BigInt.from(1000), // 0.00001 BTC
          amount: amount,
          description: description ?? 'Mock payment request',
        );

    return mockPaymentRequest;
  }

  @override
  Future<PartiallySignedTransaction> buildTransaction(
    String destination,
    Asset asset,
    BigInt amount,
    Blockchain blockchain,
  ) async {
    // Return mock PSBT
    final mockPsbt =
        _mockData['psbt'] as PartiallySignedTransaction? ??
        PartiallySignedTransaction(
          id: 'psbt-${DateTime.now().millisecondsSinceEpoch}',
          recipient: destination,
          asset: asset,
          amount: amount,
          networkFees: BigInt.from(1000), // 0.00001 BTC
        );

    return mockPsbt;
  }

  @override
  Future<Transaction> sendPayment(PartiallySignedTransaction psbt) async {
    // Return mock transaction
    final mockTransaction =
        _mockData['transaction'] as Transaction? ??
        Transaction(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          amount: psbt.amount,
          blockchain:
              psbt.asset == Asset.btc ? Blockchain.bitcoin : Blockchain.liquid,
          asset: psbt.asset,
          type: TransactionType.send,
          status: TransactionStatus.pending,
        );

    return mockTransaction;
  }
}
