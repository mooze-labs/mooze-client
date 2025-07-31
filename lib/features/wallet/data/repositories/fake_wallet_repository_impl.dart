import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../domain/entities.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/errors.dart';

class FakeWalletRepositoryImpl extends WalletRepository {
  final Map<String, dynamic> _mockData;

  FakeWalletRepositoryImpl({Map<String, dynamic>? mockData})
      : _mockData = mockData ?? {};

  @override
  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
      Option<BigInt> amount, Option<String> description) {
    return TaskEither.right(PaymentRequest(
      address: 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
      blockchain: Blockchain.bitcoin,
      asset: Asset.btc,
      fees: BigInt.from(1000),
      amount: amount.fold(() => null, (a) => a),
      description: description.fold(() => '', (d) => d),
    ));
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLightningInvoice(
      BigInt amount, Option<String> description) {
    return TaskEither.right(PaymentRequest(
      address: 'lnbc${amount}n1p0xlkz2pp5...',
      blockchain: Blockchain.lightning,
      asset: Asset.btc,
      fees: BigInt.from(100),
      amount: amount,
      description: description.fold(() => '', (d) => d),
    ));
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLiquidBitcoinInvoice(
      Option<BigInt> amount, Option<String> description) {
    return TaskEither.right(PaymentRequest(
      address: 'VJLCGjv4TeG8tyCfbVqvfZuWGjLDCDQo7DbFs7EQ4GN4P4rrxUaKZyG8DKWqfMdKwLd7fYrmECJ1uXZk',
      blockchain: Blockchain.liquid,
      asset: Asset.btc,
      fees: BigInt.from(500),
      amount: amount.fold(() => null, (a) => a),
      description: description.fold(() => '', (d) => d),
    ));
  }

  @override
  TaskEither<WalletError, PaymentRequest> createStablecoinInvoice(
      Asset asset, Option<BigInt> amount, Option<String> description) {
    return TaskEither.right(PaymentRequest(
      address: 'VJLCGjv4TeG8tyCfbVqvfZuWGjLDCDQo7DbFs7EQ4GN4P4rrxUaKZyG8DKWqfMdKwLd7fYrmECJ1uXZk',
      blockchain: Blockchain.liquid,
      asset: asset,
      fees: BigInt.from(500),
      amount: amount.fold(() => null, (a) => a),
      description: description.fold(() => '', (d) => d),
    ));
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
      buildStablecoinPaymentTransaction(
          String destination, Asset asset, double amount) {
    return TaskEither.right(PreparedStablecoinTransaction(
      destination: destination,
      asset: asset,
      amount: amount,
      networkFees: BigInt.from(500),
    ));
  }

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
      buildOnchainBitcoinPaymentTransaction(String destination, BigInt amount) {
    return TaskEither.right(PreparedOnchainBitcoinTransaction(
      destination: destination,
      amount: amount,
      networkFees: BigInt.from(2000),
    ));
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
      buildLightningPaymentTransaction(String destination, BigInt amount) {
    return TaskEither.right(PreparedLayer2BitcoinTransaction(
      destination: destination,
      amount: amount,
      networkFees: BigInt.from(100),
      blockchain: Blockchain.lightning,
    ));
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
      buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount) {
    return TaskEither.right(PreparedLayer2BitcoinTransaction(
      destination: destination,
      amount: amount,
      networkFees: BigInt.from(500),
      blockchain: Blockchain.liquid,
    ));
  }

  @override
  TaskEither<WalletError, Transaction> sendStablecoinPayment(
      PreparedStablecoinTransaction psbt) {
    return TaskEither.right(Transaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      amount: BigInt.from((psbt.amount * 100000000).toInt()),
      blockchain: psbt.blockchain,
      asset: psbt.asset,
      type: TransactionType.send,
      status: TransactionStatus.pending,
      createdAt: DateTime.now()
    ));
  }

  @override
  TaskEither<WalletError, Transaction> sendL2BitcoinPayment(
      PreparedLayer2BitcoinTransaction psbt) {
    return TaskEither.right(Transaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      amount: psbt.amount,
      blockchain: psbt.blockchain,
      asset: Asset.btc,
      type: TransactionType.send,
      status: TransactionStatus.pending,
      createdAt: DateTime.now()
    ));
  }

  @override
  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
      PreparedOnchainBitcoinTransaction psbt) {
    return TaskEither.right(Transaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      amount: psbt.amount,
      blockchain: psbt.blockchain,
      asset: Asset.btc,
      type: TransactionType.send,
      status: TransactionStatus.pending,
      createdAt: DateTime.now()
    ));
  }

  @override
  TaskEither<WalletError, List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final mockTransactions = _mockData['transactions'] as List<Transaction>? ??
        [
          Transaction(
            id: 'tx-001',
            amount: BigInt.from(1000000), // 0.01 BTC
            blockchain: Blockchain.bitcoin,
            asset: Asset.btc,
            type: TransactionType.receive,
            status: TransactionStatus.confirmed,
            createdAt: DateTime.now()
          ),
          Transaction(
            id: 'tx-002',
            amount: BigInt.from(500000000), // 5 DEPIX
            blockchain: Blockchain.liquid,
            asset: Asset.depix,
            type: TransactionType.send,
            status: TransactionStatus.pending,
            createdAt: DateTime.now()
          ),
          Transaction(
            id: 'tx-003',
            amount: BigInt.from(10000000), // 0.1 BTC
            blockchain: Blockchain.lightning,
            asset: Asset.btc,
            type: TransactionType.receive,
            status: TransactionStatus.confirmed,
            createdAt: DateTime.now()
          ),
          Transaction(
            id: 'tx-004',
            amount: BigInt.from(2500000000), // 25 USDT
            blockchain: Blockchain.liquid,
            asset: Asset.usdt,
            type: TransactionType.send,
            status: TransactionStatus.confirmed,
            createdAt: DateTime.now()
          ),
        ];

    final filteredTransactions = mockTransactions.where((tx) {
      if (type != null && tx.type != type) return false;
      if (status != null && tx.status != status) return false;
      if (asset != null && tx.asset != asset) return false;
      if (blockchain != null && tx.blockchain != blockchain) return false;
      return true;
    }).toList();

    return TaskEither.right(filteredTransactions);
  }

  @override
  TaskEither<WalletError, Balance> getBalance() {
    final mockBalance = _mockData['balance'] as Balance? ??
        {
          Asset.btc: BigInt.from(50000000), // 0.5 BTC
          Asset.depix: BigInt.from(1000000000000), // 10000 DEPIX (8 decimals)
          Asset.usdt: BigInt.from(50000000000), // 500 USDT (8 decimals)
        };

    return TaskEither.right(mockBalance);
  }
}
