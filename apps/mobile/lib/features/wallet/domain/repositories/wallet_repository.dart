import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import 'package:mooze_mobile/domain/entities/liquid_utxo.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../entities/transaction.dart';
import '../entities/payment_request.dart';
import '../entities/partially_signed_transaction.dart';

import '../enums/blockchain.dart';
import '../typedefs.dart';

abstract class WalletRepository {
  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  );
  TaskEither<WalletError, PaymentRequest> createLiquidBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  );
  TaskEither<WalletError, PaymentRequest> createStablecoinInvoice(
    Asset asset,
    Option<BigInt> amount,
    Option<String> description,
  );

  // PSBT functions
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildStablecoinPaymentTransaction(
    String destination,
    Asset asset,
    double amount,
  );
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(
    String destination,
    BigInt amount, [
    int? feeRateSatPerVByte,
    Asset? asset,
  ]);
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount);

  // DRAIN functions - send all available funds
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildDrainOnchainBitcoinTransaction(
    String destination, {
    Asset? asset,
    int? feeRateSatPerVbyte,
  });
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLiquidBitcoinTransaction(String destination);
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildDrainStablecoinTransaction(String destination, Asset asset);

  TaskEither<WalletError, Transaction> sendStablecoinPayment(
    PreparedStablecoinTransaction psbt,
  );
  TaskEither<WalletError, Transaction> sendL2BitcoinPayment(
    PreparedLayer2BitcoinTransaction psbt,
  );
  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  );

  TaskEither<WalletError, List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  });
  TaskEither<WalletError, Balance> getBalance();

  // Payment Limits

  // Receive Addresses
  TaskEither<WalletError, String> getBitcoinReceiveAddress();
  TaskEither<WalletError, String> getLiquidReceiveAddress();

  // ─────────────────────────────────────────── chain metadata
  //
  // Phase 2.3.3-prep-A: surfaces UI screens previously read from the
  // SDKs directly are routed through the repository instead. Same shape
  // as the V2 contract — Phase 2.3.3 adapter passes through unchanged.

  /// Current Bitcoin chain tip height (Electrum). Used by tx-history UI
  /// to compute confirmation counts. Returns a typed [WalletError] on
  /// failure; UI should treat that as "confirmations unknown".
  TaskEither<WalletError, int> getCurrentBitcoinBlockHeight();

  // ─────────────────────────────────────────── swap surface (LWK-backed)
  //
  // Phase 2.3.3-prep-Tier3: swap flows previously read
  // `liquidDataSourceProvider` directly to call `wallet.utxos()`,
  // `wallet.addressLastUnused()`, and `wallet.signedPsetWithExtraDetails()`.
  // They now route through here. After Phase 2.3.3 the V2 adapter
  // satisfies these methods by delegating to `LiquidWalletService`
  // directly.

  TaskEither<WalletError, List<LiquidUtxo>> getLiquidUtxos();

  TaskEither<WalletError, String> signSwapPset({
    required String pset,
    required String mnemonic,
  });

  TaskEither<WalletError, String> getLiquidSwapAddress();
}
