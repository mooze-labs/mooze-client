import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/send_request.dart';
import 'package:mooze_mobile/domain/services/liquid_wallet_service.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Legacy Liquid send/receive surface, backed by the V2 LWK service.
///
/// Replaces the Breez-backed `BreezWallet` with the same method set, so the
/// legacy [WalletRepositoryImpl] and the screens above it do not change.
/// LWK builds, signs and broadcasts every Liquid send (L-BTC and assets);
/// the fee is always paid in L-BTC.
class LiquidSpendWallet {
  LiquidSpendWallet(this._liquid);

  final LiquidWalletService _liquid;

  // ─────────────────────────────────────────── receive

  TaskEither<WalletError, PaymentRequest> createLiquidBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _receiveAddress().map((address) {
      final sats = amount.toNullable();
      return PaymentRequest(
        address: sats == null
            ? address
            : liquidBip21(address, assetId: Asset.lbtc.id, amount: sats),
        blockchain: Blockchain.liquid,
        asset: Asset.lbtc,
        fees: BigInt.zero,
        amount: sats,
        description: description.toNullable(),
      );
    });
  }

  TaskEither<WalletError, PaymentRequest> createStablecoinInvoice(
    Asset asset,
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _receiveAddress().map((address) {
      final sats = amount.toNullable();
      return PaymentRequest(
        address: liquidBip21(address, assetId: asset.id, amount: sats),
        blockchain: Blockchain.liquid,
        asset: asset,
        fees: BigInt.zero,
        amount: sats,
        description: description.toNullable(),
      );
    });
  }

  TaskEither<WalletError, String> _receiveAddress() {
    return TaskEither(() async {
      final r = await _liquid.getReceiveAddress();
      return r.mapLeft((f) => WalletError(WalletErrorType.sdkError, f.message));
    });
  }

  // ─────────────────────────────────────────── build (fee estimates)

  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount) {
    return _estimate(destination: destination, amountSat: amount).map(
      (fee) => PreparedLayer2BitcoinTransaction(
        destination: destination,
        amount: amount,
        networkFees: fee,
        blockchain: Blockchain.liquid,
        drain: false,
      ),
    );
  }

  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
  buildDrainLiquidBitcoinTransaction(String destination) {
    return _buildLbtcDrain(destination).map(
      (d) => PreparedLayer2BitcoinTransaction(
        destination: destination,
        amount: d.amount,
        networkFees: d.fee,
        blockchain: Blockchain.liquid,
        drain: true,
      ),
    );
  }

  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildStablecoinPaymentTransaction(
    String destination,
    Asset asset,
    double amount,
  ) {
    final prepared = PreparedStablecoinTransaction(
      destination: destination,
      asset: asset,
      amount: amount,
      networkFees: BigInt.zero,
      drain: false,
    );
    return _estimate(
      destination: destination,
      amountSat: prepared.satoshi,
      assetId: asset.id,
    ).map(
      (fee) => PreparedStablecoinTransaction(
        destination: destination,
        asset: asset,
        amount: amount,
        networkFees: fee,
        drain: false,
      ),
    );
  }

  TaskEither<WalletError, PreparedStablecoinTransaction>
  buildDrainStablecoinTransaction(String destination, Asset asset) {
    return _assetBalance(asset).flatMap((balance) {
      if (balance <= BigInt.zero) {
        return TaskEither.left(
          const WalletError(WalletErrorType.insufficientFunds),
        );
      }
      return _estimate(
        destination: destination,
        amountSat: balance,
        assetId: asset.id,
        drain: true,
      ).map(
        (fee) => PreparedStablecoinTransaction(
          destination: destination,
          asset: asset,
          amount: balance.toInt() / 100000000,
          networkFees: fee,
          drain: true,
        ),
      );
    });
  }

  /// L-BTC send to a Liquid address through the "on-chain" legacy flow.
  ///
  /// Breez also used this path for L-BTC → BTC chain swaps via Boltz, which
  /// no longer exist. A non-Liquid destination fails here; L-BTC → BTC goes
  /// through the SideSwap peg-out flow instead.
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildOnchainBitcoinPaymentTransaction(
    String destination,
    BigInt amount, [
    int? feeRateSatPerVByte,
  ]) {
    if (!isLiquidDestination(destination)) return _unsupportedChainSwap();
    return _estimate(
      destination: destination,
      amountSat: amount,
      feeRateSatPerVByte: feeRateSatPerVByte,
    ).map(
      (fee) => PreparedOnchainBitcoinTransaction(
        destination: destination,
        amount: amount,
        networkFees: fee,
        drain: false,
        feeRateSatPerVByte: feeRateSatPerVByte,
      ),
    );
  }

  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
  buildDrainOnchainBitcoinTransaction(
    String destination, {
    int? feeRateSatPerVbyte,
  }) {
    if (!isLiquidDestination(destination)) return _unsupportedChainSwap();
    return _buildLbtcDrain(destination, feeRateSatPerVbyte).map(
      (d) => PreparedOnchainBitcoinTransaction(
        destination: destination,
        amount: d.amount,
        networkFees: d.fee,
        drain: true,
        feeRateSatPerVByte: feeRateSatPerVbyte,
      ),
    );
  }

  // ─────────────────────────────────────────── send

  TaskEither<WalletError, Transaction> sendL2BitcoinPayment(
    PreparedLayer2BitcoinTransaction psbt,
  ) {
    return _send(
      destination: psbt.destination,
      amountSat: psbt.amount,
      drain: psbt.drain,
      asset: Asset.lbtc,
    );
  }

  TaskEither<WalletError, Transaction> sendStablecoinPayment(
    PreparedStablecoinTransaction psbt,
  ) {
    return _send(
      destination: psbt.destination,
      amountSat: psbt.satoshi,
      drain: psbt.drain,
      asset: psbt.asset,
    );
  }

  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  ) {
    if (!isLiquidDestination(psbt.destination)) return _unsupportedChainSwap();
    return _send(
      destination: psbt.destination,
      amountSat: psbt.amount,
      drain: psbt.drain,
      asset: Asset.lbtc,
      feeRateSatPerVByte: psbt.feeRateSatPerVByte,
    );
  }

  // ─────────────────────────────────────────── helpers

  TaskEither<WalletError, BigInt> _estimate({
    required String destination,
    required BigInt amountSat,
    String? assetId,
    bool drain = false,
    int? feeRateSatPerVByte,
  }) {
    return TaskEither(() async {
      final r = await _liquid.estimateFee(
        _request(
          destination: destination,
          amountSat: amountSat,
          assetId: assetId,
          drain: drain,
          feeRateSatPerVByte: feeRateSatPerVByte,
        ),
      );
      return r.bimap(
        (f) => WalletError(WalletErrorType.transactionFailed, f.message),
        (e) => BigInt.from(e.absoluteFeeSat),
      );
    });
  }

  /// L-BTC drain: the amount the destination receives is the balance minus
  /// the fee, which only the built transaction knows.
  TaskEither<WalletError, ({BigInt amount, BigInt fee})> _buildLbtcDrain(
    String destination, [
    int? feeRateSatPerVByte,
  ]) {
    return TaskEither(() async {
      final r = await _liquid.buildLbtcSend(
        destination: bareLiquidAddress(destination),
        amountSat: BigInt.zero,
        feeRateSatPerVb: feeRateSatPerVByte?.toDouble(),
        drain: true,
      );
      return r.bimap(
        (f) => WalletError(WalletErrorType.transactionFailed, f.message),
        (d) => (amount: d.amountSat, fee: d.feeSat),
      );
    });
  }

  TaskEither<WalletError, BigInt> _assetBalance(Asset asset) {
    return TaskEither(() async {
      final r = await _liquid.getBalance();
      return r.bimap(
        (f) => WalletError(WalletErrorType.connectionError, f.message),
        (b) {
          for (final a in b.assets) {
            if (a.assetId == asset.id) return BigInt.from(a.amountSat);
          }
          return BigInt.zero;
        },
      );
    });
  }

  TaskEither<WalletError, Transaction> _send({
    required String destination,
    required BigInt amountSat,
    required bool drain,
    required Asset asset,
    int? feeRateSatPerVByte,
  }) {
    return TaskEither(() async {
      final r = await _liquid.sendOnchain(
        _request(
          destination: destination,
          amountSat: amountSat,
          assetId: asset == Asset.lbtc ? null : asset.id,
          drain: drain,
          feeRateSatPerVByte: feeRateSatPerVByte,
        ),
      );
      return r.bimap(
        (f) => WalletError(WalletErrorType.transactionFailed, f.message),
        (result) => Transaction(
          id: result.txId,
          amount: BigInt.from(result.transaction.amountSat),
          blockchain: Blockchain.liquid,
          asset: asset,
          type: TransactionType.send,
          status: TransactionStatus.pending,
          createdAt: result.transaction.timestamp,
          destination: destination,
          feesSat: result.feePaidSat == null
              ? null
              : BigInt.from(result.feePaidSat!),
        ),
      );
    });
  }

  SendRequest _request({
    required String destination,
    required BigInt amountSat,
    String? assetId,
    bool drain = false,
    int? feeRateSatPerVByte,
  }) {
    return SendRequest(
      chain: ChainId.liquid,
      destination: bareLiquidAddress(destination),
      amountSat: amountSat.toInt(),
      assetId: assetId,
      drain: drain,
      feeRateOverrideSatPerVByte: feeRateSatPerVByte?.toDouble(),
    );
  }

  TaskEither<WalletError, T> _unsupportedChainSwap<T>() {
    return TaskEither.left(
      const WalletError(
        WalletErrorType.invalidAddress,
        'L-BTC → BTC usa o fluxo de peg-out',
      ),
    );
  }
}

/// Liquid BIP21 URI in the exact shape Breez produced, so QR codes and
/// payer wallets see no change: L-BTC with an amount puts `assetid` first;
/// other assets put `amount` first.
String liquidBip21(String address, {required String assetId, BigInt? amount}) {
  if (amount == null) return 'liquidnetwork:$address?assetid=$assetId';
  final value = _formatUnits(amount);
  if (assetId == Asset.lbtc.id) {
    return 'liquidnetwork:$address?assetid=$assetId&amount=$value';
  }
  return 'liquidnetwork:$address?amount=$value&assetid=$assetId';
}

/// Base units to an 8-decimal string, without floating point.
String _formatUnits(BigInt units) {
  final base = BigInt.from(100000000);
  final whole = units ~/ base;
  final frac = (units % base).toString().padLeft(8, '0');
  return '$whole.$frac';
}

/// The address part of a Liquid destination: strips a `liquidnetwork:` or
/// `liquid:` scheme and any BIP21 query. LWK only accepts a bare address.
String bareLiquidAddress(String destination) {
  var d = destination.trim();
  for (final scheme in const ['liquidnetwork:', 'liquid:']) {
    if (d.toLowerCase().startsWith(scheme)) {
      d = d.substring(scheme.length);
      break;
    }
  }
  final q = d.indexOf('?');
  return q == -1 ? d : d.substring(0, q);
}

/// True for a destination LWK can pay: a Liquid address, bare or BIP21.
bool isLiquidDestination(String destination) {
  final d = destination.trim().toLowerCase();
  if (d.startsWith('liquidnetwork:') || d.startsWith('liquid:')) return true;
  final a = bareLiquidAddress(destination);
  const prefixes = ['lq1', 'ex1', 'tlq1', 'tex1', 'el1', 'ert1'];
  final lower = a.toLowerCase();
  if (prefixes.any(lower.startsWith)) return true;
  // Base58 confidential (VJL…, Az…) and unconfidential (G…, H…, Q…) forms.
  return RegExp(r'^(VJL|VT|VG|Az|G|H|Q)[1-9A-HJ-NP-Za-km-z]{25,}$').hasMatch(a);
}
