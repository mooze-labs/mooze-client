import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/data/fake_wallet_repository_impl.dart';
import 'package:mooze_mobile/features/wallet/data/examples/mock_data_examples.dart';

void main() {
  group('FakeWalletRepositoryImpl', () {
    test(
      'should return default mock data when no custom data provided',
      () async {
        final repository = FakeWalletRepositoryImpl();

        final balance = await repository.getBalance();
        final transactions = await repository.getTransactions();

        expect(balance, isA<Map<Asset, BigInt>>());
        expect(balance[Asset.btc], BigInt.from(50000000));
        expect(transactions, hasLength(3));
      },
    );

    test('should return custom mock data when provided', () async {
      final customData = MockDataExamples.highBalanceWallet;
      final repository = FakeWalletRepositoryImpl(mockData: customData);

      final balance = await repository.getBalance();
      final transactions = await repository.getTransactions();

      expect(balance[Asset.btc], BigInt.from(1000000000)); // 10 BTC
      expect(transactions, hasLength(1));
      expect(transactions.first.id, 'tx-high-001');
    });

    test('should filter transactions by type', () async {
      final customData = MockDataExamples.manyTransactionsWallet;
      final repository = FakeWalletRepositoryImpl(mockData: customData);

      final sendTransactions = await repository.getTransactions(
        type: TransactionType.send,
      );

      expect(
        sendTransactions.every((tx) => tx.type == TransactionType.send),
        true,
      );
    });

    test('should filter transactions by status', () async {
      final customData = MockDataExamples.manyTransactionsWallet;
      final repository = FakeWalletRepositoryImpl(mockData: customData);

      final pendingTransactions = await repository.getTransactions(
        status: TransactionStatus.pending,
      );

      expect(
        pendingTransactions.every(
          (tx) => tx.status == TransactionStatus.pending,
        ),
        true,
      );
    });

    test('should filter transactions by asset', () async {
      final customData = MockDataExamples.manyTransactionsWallet;
      final repository = FakeWalletRepositoryImpl(mockData: customData);

      final btcTransactions = await repository.getTransactions(
        asset: Asset.btc,
      );

      expect(btcTransactions.every((tx) => tx.asset == Asset.btc), true);
    });

    test('should create payment request with custom data', () async {
      final customData = MockDataExamples.getCustomPaymentRequest(
        address: 'bc1qtest123',
        amount: BigInt.from(1000000),
        asset: Asset.btc,
        blockchain: Blockchain.bitcoin,
      );
      final repository = FakeWalletRepositoryImpl(mockData: customData);

      final paymentRequest = await repository.createInvoice(
        Asset.btc,
        Blockchain.bitcoin,
        BigInt.from(1000000),
        'Test payment',
      );

      expect(paymentRequest.address, 'bc1qtest123');
      expect(paymentRequest.amount, BigInt.from(1000000));
    });

    test('should build transaction with custom PSBT data', () async {
      final customData = MockDataExamples.getCustomPsbt(
        recipient: 'bc1qrecipient123',
        amount: BigInt.from(500000),
        asset: Asset.depix,
        networkFees: BigInt.from(500),
      );
      final repository = FakeWalletRepositoryImpl(mockData: customData);

      final psbt = await repository.buildTransaction(
        'bc1qrecipient123',
        Asset.depix,
        BigInt.from(500000),
        Blockchain.liquid,
      );

      expect(psbt.recipient, 'bc1qrecipient123');
      expect(psbt.amount, BigInt.from(500000));
      expect(psbt.networkFees, BigInt.from(500));
    });

    test('should send payment with custom transaction data', () async {
      final customData = MockDataExamples.getCustomTransaction(
        id: 'custom-tx-123',
        amount: BigInt.from(750000),
        asset: Asset.usdt,
        blockchain: Blockchain.liquid,
        type: TransactionType.send,
        status: TransactionStatus.confirmed,
      );
      final repository = FakeWalletRepositoryImpl(mockData: customData);

      final psbt = PartiallySignedTransaction(
        id: 'test-psbt',
        recipient: 'bc1qtest123',
        asset: Asset.usdt,
        amount: BigInt.from(750000),
        networkFees: BigInt.from(1000),
      );

      final transaction = await repository.sendPayment(psbt);

      expect(transaction.id, 'custom-tx-123');
      expect(transaction.amount, BigInt.from(750000));
      expect(transaction.status, TransactionStatus.confirmed);
    });

    test('should handle empty wallet scenario', () async {
      final customData = MockDataExamples.emptyWallet;
      final repository = FakeWalletRepositoryImpl(mockData: customData);

      final balance = await repository.getBalance();
      final transactions = await repository.getTransactions();

      expect(balance, isEmpty);
      expect(transactions, isEmpty);
    });
  });
}
