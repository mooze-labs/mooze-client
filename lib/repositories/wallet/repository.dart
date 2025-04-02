import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/transaction.dart';

abstract class WalletRepository {
  /// Initializes a wallet
  Future<void> initializeWallet(bool mainnet, String mnemonic);

  /// Synchronizes a given wallet with nodes
  Future<void> sync();

  /// Generates an address
  Future<String> generateAddress();

  /// Retrieves owned assets
  Future<List<OwnedAsset>> getOwnedAssets();

  /// Generates pre-signed transaction
  Future<PartiallySignedTransaction> buildPartiallySignedTransaction(
    OwnedAsset asset,
    String recipient,
    int amount,
    double? feeRate,
  );

  /// Signs and broadcasts transaction
  Future<Transaction> signTransaction(PartiallySignedTransaction pst);

  /// Retrieves transaction history
  Future<List<TransactionRecord>> getTransactionHistory();
}
