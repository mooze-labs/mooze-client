import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class TransactionMockNotifier extends StateNotifier<List<Transaction>> {
  TransactionMockNotifier() : super([]);

  void addMockTransaction(Transaction transaction) {
    state = [...state, transaction];
  }

  void addMockTransactions(List<Transaction> transactions) {
    state = [...state, ...transactions];
  }

  void clearMockTransactions() {
    state = [];
  }

  void removeMockTransaction(String id) {
    state = state.where((tx) => tx.id != id).toList();
  }

  Transaction createRefundablePegInTransaction({
    String? customId,
    BigInt? customAmount,
    DateTime? customDate,
  }) {
    final amount = customAmount ?? BigInt.from(52172);
    final fees = BigInt.from(402);
    final sentAmount = amount + fees; // 52574

    return Transaction(
      // Transaction IDs
      id:
          customId ??
          '5e2159e9b5fbf7023b2800066dbb9bb7ba4f5de423495d6a8a7ac938b4746415',
      sendTxId:
          '2622dd4f5a1c69f7cea5763482fa470d726dd3cfa316790b22067cf62e6bc268', // Bitcoin lockup tx
      receiveTxId:
          customId ??
          '5e2159e9b5fbf7023b2800066dbb9bb7ba4f5de423495d6a8a7ac938b4746415', // Liquid claim tx (failed)
      // Amounts
      amount: amount,
      sentAmount: sentAmount, // Amount sent including fees
      receivedAmount: amount, // Amount that would be received (but failed)
      // Assets & Blockchains
      asset: Asset.btc, // Original asset
      fromAsset: Asset.btc, // From Bitcoin
      toAsset: Asset.lbtc, // To Liquid (but failed)
      blockchain: Blockchain.bitcoin, // Submarine swap uses Bitcoin blockchain
      sendBlockchain: Blockchain.bitcoin, // Sent from Bitcoin
      receiveBlockchain:
          Blockchain.liquid, // Should receive on Liquid (but failed)
      // Transaction type and status
      type: TransactionType.submarine,
      status: TransactionStatus.refundable, // KEY: Status that enables refund
      // Timestamp
      createdAt: customDate ?? DateTime(2026, 2, 4, 0, 17, 10),

      // Destination address (Bitcoin address where funds were locked)
      destination:
          'bc1p62e2r4jnr3v985uqk06yjc2s7422js2qqp35kumg03xwyw8wzyfqz678nc',

      // Explorer URL for the lockup transaction
      blockchainUrl:
          'https://blockstream.info/tx/2622dd4f5a1c69f7cea5763482fa470d726dd3cfa316790b22067cf62e6bc268',

      // Confirmation and preimage
      confirmationHeight: null,
      preimage: null,
    );
  }

  Transaction createRefundablePegOutTransaction({
    String? customId,
    BigInt? customAmount,
    DateTime? customDate,
  }) {
    final amount = customAmount ?? BigInt.from(100000);
    final fees = BigInt.from(500);
    final receivedAmount = amount - fees;

    return Transaction(
      // Transaction IDs
      id: customId ?? 'pegout_mock_id_${DateTime.now().millisecondsSinceEpoch}',
      sendTxId:
          'liquid_tx_mock_${DateTime.now().millisecondsSinceEpoch}', // Liquid claim tx
      receiveTxId:
          'btc_tx_mock_${DateTime.now().millisecondsSinceEpoch}', // Bitcoin lockup tx (failed)
      // Amounts
      amount: amount,
      sentAmount: amount, // Amount sent from Liquid
      receivedAmount:
          receivedAmount, // Amount that would be received on Bitcoin (but failed)
      // Assets & Blockchains
      asset: Asset.lbtc, // Original asset
      fromAsset: Asset.lbtc, // From Liquid
      toAsset: Asset.btc, // To Bitcoin (but failed)
      blockchain: Blockchain.bitcoin, // Submarine swap uses Bitcoin blockchain
      sendBlockchain: Blockchain.liquid, // Sent from Liquid
      receiveBlockchain:
          Blockchain.bitcoin, // Should receive on Bitcoin (but failed)
      // Transaction type and status
      type: TransactionType.submarine,
      status: TransactionStatus.refundable, // KEY: Status that enables refund
      // Timestamp
      createdAt:
          customDate ?? DateTime.now().subtract(const Duration(hours: 3)),

      // Destination address
      destination: 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',

      // Explorer URL
      blockchainUrl:
          'https://blockstream.info/tx/${customId ?? "pegout_mock_id"}',

      // Confirmation and preimage
      confirmationHeight: null,
      preimage: null,
    );
  }

  void loadDefaultMockTransactions() {
    clearMockTransactions();
    addMockTransaction(createRefundablePegInTransaction());

    // Peg Out refundable
    addMockTransaction(
      createRefundablePegOutTransaction(customAmount: BigInt.from(150000)),
    );

    addMockTransaction(
      Transaction(
        id: 'confirmed_pegin_${DateTime.now().millisecondsSinceEpoch}',
        amount: BigInt.from(75000),
        sentAmount: BigInt.from(75300),
        receivedAmount: BigInt.from(75000),
        asset: Asset.btc,
        fromAsset: Asset.btc,
        toAsset: Asset.lbtc,
        blockchain: Blockchain.bitcoin,
        sendBlockchain: Blockchain.bitcoin,
        receiveBlockchain: Blockchain.liquid,
        type: TransactionType.submarine,
        status: TransactionStatus.confirmed,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        destination: 'bc1qconfirmed123456789abcdefghijklmnopqrstuv',
        blockchainUrl: 'https://blockstream.info/tx/confirmed_mock',
        sendTxId: 'btc_confirmed_${DateTime.now().millisecondsSinceEpoch}',
        receiveTxId:
            'liquid_confirmed_${DateTime.now().millisecondsSinceEpoch}',
        confirmationHeight: 800000,
        preimage: null,
      ),
    );
  }
}

final transactionMockProvider =
    StateNotifierProvider<TransactionMockNotifier, List<Transaction>>((ref) {
      return TransactionMockNotifier();
    });

final combinedTransactionProvider = Provider<List<Transaction>>((ref) {
  final mockTransactions = ref.watch(transactionMockProvider);

  return mockTransactions;
});
