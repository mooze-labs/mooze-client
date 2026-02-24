import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

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
}
