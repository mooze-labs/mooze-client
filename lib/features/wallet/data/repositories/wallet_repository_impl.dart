import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/bitcoin.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/liquid.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/infra/lwk/wallet.dart';

import './wallet_repository_impl/breez.dart';

class WalletRepositoryImpl extends WalletRepository {
  final BreezWallet _breezWallet;
  final BitcoinWallet _bitcoinWallet;
  final LiquidWallet _liquidWallet;

  WalletRepositoryImpl(
    BreezWallet breezWallet,
    BitcoinWallet bitcoinWallet,
    LiquidWallet liquidWallet,
  ) : _breezWallet = breezWallet,
      _bitcoinWallet = bitcoinWallet,
      _liquidWallet = liquidWallet;

  @override
  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _bitcoinWallet.createBitcoinInvoice(amount, description);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLightningInvoice(
    BigInt amount,
    Option<String> description,
  ) {
    return _breezWallet.createLightningInvoice(amount, description);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLiquidBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _breezWallet.createLiquidBitcoinInvoice(amount, description);
  }

  @override
  TaskEither<WalletError, PaymentRequest> createStablecoinInvoice(
    Asset asset,
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _breezWallet.createStablecoinInvoice(asset, amount, description);
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildStablecoinPaymentTransaction(
    String destination,
    Asset asset,
    double amount,
  ) {
    return _breezWallet.buildStablecoinPaymentTransaction(
      destination,
      asset,
      amount,
    );
  }

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(String destination, BigInt amount) {
    return _bitcoinWallet.buildOnchainBitcoinPaymentTransaction(
      destination,
      amount,
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLightningPaymentTransaction(String destination, BigInt amount) {
    return _breezWallet.buildLightningPaymentTransaction(destination, amount);
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount) {
    return _breezWallet.buildLiquidBitcoinPaymentTransaction(
      destination,
      amount,
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLightningTransaction(String destination) {
    return _breezWallet.buildDrainLightningTransaction(destination);
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLiquidBitcoinTransaction(String destination) {
    return _breezWallet.buildDrainLiquidBitcoinTransaction(destination);
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildDrainStablecoinTransaction(String destination, Asset asset) {
    return _breezWallet.buildDrainStablecoinTransaction(destination, asset);
  }

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildDrainOnchainBitcoinTransaction(String destination) {
    return _bitcoinWallet.buildDrainOnchainBitcoinTransaction(destination);
  }

  @override
  TaskEither<WalletError, Transaction> sendL2BitcoinPayment(
    PreparedLayer2BitcoinTransaction psbt,
  ) {
    return _breezWallet.sendL2BitcoinPayment(psbt);
  }

  @override
  TaskEither<WalletError, Transaction> sendStablecoinPayment(
    PreparedStablecoinTransaction psbt,
  ) {
    return _breezWallet.sendStablecoinPayment(psbt);
  }

  @override
  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  ) {
    return _breezWallet.sendOnchainBitcoinPayment(psbt);
  }

  @override
  TaskEither<WalletError, Balance> getBalance() {
    final breezBalance = _breezWallet.getBalance();
    final bitcoinBalance = _bitcoinWallet.balance;
    final unifiedBalance = breezBalance.flatMap((breezBal) {
      return TaskEither.fromEither(
        bitcoinBalance.flatMap((btcBal) {
          breezBal[Asset.btc] = btcBal;
          return Either<WalletError, Balance>.right(breezBal);
        }),
      );
    });

    return unifiedBalance;
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
    final breezTransactions = _breezWallet.getTransactions(
      type: type,
      status: status,
      asset: asset,
      blockchain: blockchain,
      startDate: startDate,
      endDate: endDate,
    );

    final liquidTransactions = _liquidWallet.getTransactions(
      type: type,
      status: status,
      blockchain: blockchain,
      asset: asset,
      startDate: startDate,
      endDate: endDate,
    );

    final bitcoinTransactions = _bitcoinWallet.getTransactions(
      type: type,
      status: status,
      blockchain: blockchain,
      asset: asset,
      startDate: startDate,
      endDate: endDate,
    );

    final layer2Transactions = breezTransactions.flatMap((breezTxs) {
      return liquidTransactions.flatMap((liquidTxs) {
        final breezIds = breezTxs.map((tx) => tx.id).toSet();
        final filteredLiquidTxs =
            liquidTxs.where((tx) => !breezIds.contains(tx.id)).toList();
        final allTransactions = [...breezTxs, ...filteredLiquidTxs];
        return TaskEither.right(allTransactions);
      });
    });

    return layer2Transactions.flatMap(
      (transactions) => TaskEither.fromEither(
        bitcoinTransactions.flatMap(
          (btcTransactions) => right([...transactions, ...btcTransactions]),
        ),
      ),
    );
  }
}
