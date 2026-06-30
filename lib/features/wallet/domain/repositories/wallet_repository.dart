import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import 'package:mooze_mobile/domain/entities/liquid_utxo.dart';
import 'package:mooze_mobile/domain/entities/refund.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../entities/transaction.dart';
import '../entities/payment_request.dart';
import '../entities/partially_signed_transaction.dart';
import '../entities/payment_limits.dart';

import '../enums/blockchain.dart';
import '../typedefs.dart';

abstract class WalletRepository {
  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  );
  TaskEither<WalletError, PaymentRequest> createLightningInvoice(
    BigInt amount,
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
  buildLightningPaymentTransaction(String destination, BigInt amount);
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
  buildDrainLightningTransaction(String destination);
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
  TaskEither<WalletError, LightningPaymentLimitsResponse>
  fetchLightningLimits();
  TaskEither<WalletError, PaymentLimits> fetchOnchainLimits();
  TaskEither<WalletError, PaymentLimits> fetchOnchainReceiveLimits();

  // Peg-out (LBTC → BTC)
  TaskEither<WalletError, BigInt> preparePegOut({
    required BigInt receiverAmountSat,
    int? feeRateSatPerVbyte,
    bool drain = false,
  });
  TaskEither<WalletError, Transaction> executePegOut({
    required String btcAddress,
    required BigInt receiverAmountSat,
    required BigInt totalFeesSat,
    int? feeRateSatPerVbyte,
    bool drain = false,
  });

  TaskEither<WalletError, ({String bitcoinAddress, BigInt feesSat})>
  preparePegIn({required BigInt payerAmountSat});

  TaskEither<WalletError, ({String bitcoinAddress, BigInt feesSat})>
  preparePegInWithFees({
    required BigInt payerAmountSat,
    int? feeRateSatPerVByte,
  });

  TaskEither<WalletError, ({BigInt breezFeesSat, BigInt bdkFeesSat})>
  preparePegInWithFullFees({
    required BigInt payerAmountSat,
    int? feeRateSatPerVByte,
  });

  TaskEither<WalletError, Transaction> executePegIn({
    required BigInt amount,
    int? feeRateSatPerVByte,
    bool drain = false,
  });

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

  // ─────────────────────────────────────────── refund surface
  //
  // Phase 2.3.3-prep-A2/A3: refund flows previously read
  // `breezClientProvider` directly to invoke `listRefundables`,
  // `recommendedFees`, `prepareRefund`, `refund`. They now route through
  // here and consume V2 domain types — same field shapes as Breez SDK
  // types so widgets can switch their imports without changing field
  // accesses. After Phase 2.3.3 the V2 adapter satisfies these methods
  // by delegating to `LightningWalletService` directly.

  TaskEither<WalletError, List<RefundableSwap>> listRefundableSwaps();

  TaskEither<WalletError, MempoolFees> getRecommendedFees();

  TaskEither<WalletError, PrepareRefundOutcome> prepareRefund(
      PrepareRefundParams params);

  TaskEither<WalletError, RefundOutcome> executeRefund(
      ExecuteRefundParams params);

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
