import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

// `Transaction` collides with the legacy domain Transaction below. Only
// `AppDatabase` and `TransactionsCompanion` are needed from drift.
import 'package:mooze_mobile/database/database.dart' hide Transaction;
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/liquid_utxo.dart' as v2;
import 'package:mooze_mobile/domain/entities/send_request.dart';
import 'package:mooze_mobile/domain/entities/transaction.dart' as v2;
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/domain/services/bitcoin_wallet_service.dart';
import 'package:mooze_mobile/domain/services/liquid_wallet_service.dart';
import 'package:mooze_mobile/features/wallet/data/mappers/v2_transaction_mapper.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/liquid_spend.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/typedefs.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/shared/concurrency/liquid_spend_coordinator.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Legacy [WalletRepository] backed only by the V2 domain services.
///
/// It depends on [LiquidWalletService] and [BitcoinWalletService], never on
/// LWK, BDK or mooze-core types. So it works with the LWK/BDK services and
/// with the Core* services (`--dart-define=MOOZE_CORE=true`).
///
/// Each method reproduces the behavior of `WalletRepositoryImpl` and its
/// `BitcoinWallet` / `LiquidWallet` / `LiquidSpendWallet` parts. Liquid send
/// and receive delegate to [LiquidSpendWallet], which already uses only the
/// Liquid service.
class ServiceBackedWalletRepository extends WalletRepository {
  ServiceBackedWalletRepository({
    LiquidWalletService? liquid,
    BitcoinWalletService? bitcoin,
    SwapAuditRepository? swapAudit,
    AppDatabase? database,
    AppLoggerService? logger,
    LiquidSpendCoordinator? spendCoordinator,
  })  : _liquid = liquid,
        _liquidSpend = liquid == null ? null : LiquidSpendWallet(liquid),
        _bitcoin = bitcoin,
        _swapAudit = swapAudit,
        _database = database,
        _logger = logger,
        _spendCoordinator = spendCoordinator ?? LiquidSpendCoordinator.instance;

  final LiquidWalletService? _liquid;
  final LiquidSpendWallet? _liquidSpend;
  final BitcoinWalletService? _bitcoin;
  final SwapAuditRepository? _swapAudit;
  final AppDatabase? _database;
  final AppLoggerService? _logger;
  final LiquidSpendCoordinator _spendCoordinator;

  static const _liquidUnavailable = 'Liquid wallet not available';
  static const _bitcoinUnavailable = 'Bitcoin wallet not available';

  // ─────────────────────────────────────────── availability helpers

  TaskEither<WalletError, T> _withLiquidSpend<T>(
    TaskEither<WalletError, T> Function(LiquidSpendWallet) fn,
  ) {
    final spend = _liquidSpend;
    if (spend == null) {
      return TaskEither.left(
        const WalletError(WalletErrorType.sdkError, _liquidUnavailable),
      );
    }
    return fn(spend);
  }

  TaskEither<WalletError, T> _withLiquid<T>(
    TaskEither<WalletError, T> Function(LiquidWalletService) fn,
  ) {
    final liquid = _liquid;
    if (liquid == null) {
      return TaskEither.left(
        const WalletError(WalletErrorType.sdkError, _liquidUnavailable),
      );
    }
    return fn(liquid);
  }

  TaskEither<WalletError, T> _withBitcoin<T>(
    TaskEither<WalletError, T> Function(BitcoinWalletService) fn,
  ) {
    final bitcoin = _bitcoin;
    if (bitcoin == null) {
      return TaskEither.left(
        const WalletError(WalletErrorType.sdkError, _bitcoinUnavailable),
      );
    }
    return fn(bitcoin);
  }

  /// Runs [call] and maps a [ServiceFailure] with [onFailure]. A thrown
  /// error goes through [onFailure] as well, with its string as message.
  static TaskEither<WalletError, T> _service<T>(
    Future<Either<ServiceFailure, T>> Function() call,
    WalletError Function(String message) onFailure,
  ) {
    return TaskEither(() async {
      try {
        final r = await call();
        return r.mapLeft((f) => onFailure(f.message));
      } catch (e) {
        return Left(onFailure(e.toString()));
      }
    });
  }

  // ─────────────────────────────────────────── invoices

  @override
  TaskEither<WalletError, PaymentRequest> createBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    // Same as `BitcoinWallet.createBitcoinInvoice`: the request carries the
    // bare address. The amount is metadata only, not a BIP21 URI.
    return _bitcoinReceiveAddress().map(
      (address) => PaymentRequest(
        address: address,
        blockchain: Blockchain.bitcoin,
        asset: Asset.btc,
        fees: BigInt.zero,
        amount: amount.toNullable(),
        description: description.toNullable(),
      ),
    );
  }

  @override
  TaskEither<WalletError, PaymentRequest> createLiquidBitcoinInvoice(
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _withLiquidSpend(
      (liquid) => liquid.createLiquidBitcoinInvoice(amount, description),
    );
  }

  @override
  TaskEither<WalletError, PaymentRequest> createStablecoinInvoice(
    Asset asset,
    Option<BigInt> amount,
    Option<String> description,
  ) {
    return _withLiquidSpend(
      (liquid) => liquid.createStablecoinInvoice(asset, amount, description),
    );
  }

  // ─────────────────────────────────────────── build

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
      buildStablecoinPaymentTransaction(
    String destination,
    Asset asset,
    double amount,
  ) {
    return _withLiquidSpend(
      (liquid) =>
          liquid.buildStablecoinPaymentTransaction(destination, asset, amount),
    );
  }

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
      buildOnchainBitcoinPaymentTransaction(
    String destination,
    BigInt amount, [
    int? feeRateSatPerVByte,
    Asset? asset,
  ]) {
    if (asset == Asset.lbtc || isLiquidDestination(destination)) {
      return _withLiquidSpend(
        (liquid) => liquid.buildOnchainBitcoinPaymentTransaction(
          destination,
          amount,
          feeRateSatPerVByte,
        ),
      );
    }

    return _withBitcoin(
      (btc) => _service(
        () => btc.estimateFee(
          _bitcoinRequest(
            destination: destination,
            amountSat: amount,
            feeRateSatPerVByte: feeRateSatPerVByte,
          ),
        ),
        _bitcoinBuildError,
      ).map(
        (fee) => PreparedOnchainBitcoinTransaction(
          destination: destination,
          amount: amount,
          networkFees: BigInt.from(fee.absoluteFeeSat),
          drain: false,
          feeRateSatPerVByte: feeRateSatPerVByte,
        ),
      ),
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
      buildLiquidBitcoinPaymentTransaction(String destination, BigInt amount) {
    return _withLiquidSpend(
      (liquid) =>
          liquid.buildLiquidBitcoinPaymentTransaction(destination, amount),
    );
  }

  @override
  TaskEither<WalletError, PreparedLayer2BitcoinTransaction>
      buildDrainLiquidBitcoinTransaction(String destination) {
    return _withLiquidSpend(
      (liquid) => liquid.buildDrainLiquidBitcoinTransaction(destination),
    );
  }

  @override
  TaskEither<WalletError, PreparedStablecoinTransaction>
      buildDrainStablecoinTransaction(String destination, Asset asset) {
    return _withLiquidSpend(
      (liquid) => liquid.buildDrainStablecoinTransaction(destination, asset),
    );
  }

  @override
  TaskEither<WalletError, PreparedOnchainBitcoinTransaction>
      buildDrainOnchainBitcoinTransaction(
    String destination, {
    Asset? asset,
    int? feeRateSatPerVbyte,
  }) {
    if (asset == Asset.lbtc || isLiquidDestination(destination)) {
      return _withLiquidSpend(
        (liquid) => liquid.buildDrainOnchainBitcoinTransaction(
          destination,
          feeRateSatPerVbyte: feeRateSatPerVbyte,
        ),
      );
    }

    return _withBitcoin((btc) {
      // NOTE(core): the old impl read `sentAndReceived(...).sent` from the
      // built drain PSBT (the value of every wallet input). The service has
      // no such call. A drain spends every wallet UTXO, so the total wallet
      // balance is the same value.
      final total = _service(
        () => btc.getBalance(),
        (m) => WalletError(WalletErrorType.transactionFailed, m),
      ).map((b) => BigInt.from(b.totalSatForChain(ChainId.bitcoin)));

      final fee = _service(
        () => btc.estimateFee(
          _bitcoinRequest(
            destination: destination,
            amountSat: BigInt.zero,
            drain: true,
            feeRateSatPerVByte: feeRateSatPerVbyte,
          ),
        ),
        _bitcoinBuildError,
      );

      return fee.flatMap(
        (estimate) => total.map(
          (amount) => PreparedOnchainBitcoinTransaction(
            destination: destination,
            amount: amount,
            networkFees: BigInt.from(estimate.absoluteFeeSat),
            drain: true,
            feeRateSatPerVByte: feeRateSatPerVbyte,
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────── send

  @override
  TaskEither<WalletError, Transaction> sendL2BitcoinPayment(
    PreparedLayer2BitcoinTransaction psbt,
  ) {
    return _withLiquidSpendLock(
      'lwk:sendL2Bitcoin',
      () => _withLiquidSpend((liquid) => liquid.sendL2BitcoinPayment(psbt)),
    );
  }

  @override
  TaskEither<WalletError, Transaction> sendStablecoinPayment(
    PreparedStablecoinTransaction psbt,
  ) {
    return _withLiquidSpendLock(
      'lwk:sendStablecoin',
      () => _withLiquidSpend((liquid) => liquid.sendStablecoinPayment(psbt)),
    );
  }

  TaskEither<WalletError, Transaction> _withLiquidSpendLock(
    String label,
    TaskEither<WalletError, Transaction> Function() body,
  ) {
    return TaskEither(() async {
      try {
        return await _spendCoordinator.protect(label, () => body().run());
      } on LiquidSpendLockTimeout catch (e) {
        return left(
          WalletError(WalletErrorType.transactionFailed, e.toString()),
        );
      }
    });
  }

  @override
  TaskEither<WalletError, Transaction> sendOnchainBitcoinPayment(
    PreparedOnchainBitcoinTransaction psbt,
  ) {
    if (isLiquidDestination(psbt.destination)) {
      return _withLiquidSpend(
        (liquid) => liquid.sendOnchainBitcoinPayment(psbt),
      );
    }

    return _withBitcoin(
      (btc) => _service(
        // The service builds, signs and broadcasts. It also emits the
        // `created` event, so no `registerExternalBroadcast` call is needed.
        () => btc.sendOnchain(
          _bitcoinRequest(
            destination: psbt.destination,
            amountSat: psbt.amount,
            drain: psbt.drain,
            feeRateSatPerVByte: psbt.feeRateSatPerVByte,
          ),
        ),
        _bitcoinSendError,
      ).flatMap(
        (result) => TaskEither(() async {
          // Best-effort write to the legacy drift table, as the old impl
          // did. A DB error must not fail the send: the funds already moved.
          await _persistOutgoingBitcoinTx(
            txid: result.txId,
            destination: psbt.destination,
            amountSats: psbt.amount,
            feeRateSatPerVByte: psbt.feeRateSatPerVByte,
            drain: psbt.drain,
          );
          return Right(
            Transaction(
              id: result.txId,
              amount: psbt.amount,
              blockchain: Blockchain.bitcoin,
              asset: Asset.btc,
              type: TransactionType.send,
              status: TransactionStatus.pending,
              createdAt: DateTime.now(),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _persistOutgoingBitcoinTx({
    required String txid,
    required String destination,
    required BigInt amountSats,
    required int? feeRateSatPerVByte,
    required bool drain,
  }) async {
    final database = _database;
    if (database == null) return;
    try {
      await database.upsertTransaction(
        TransactionsCompanion.insert(
          id: txid,
          assetId: 'btc',
          amount: amountSats,
          type: 'send',
          status: 'pending',
          createdAt: DateTime.now(),
          confirmations: const Value(0),
          txHash: Value(txid),
          address: Value(destination),
          metadata: Value(
            jsonEncode({
              'feeRateSatPerVByte': feeRateSatPerVByte,
              'drain': drain,
            }),
          ),
          blockchain: 'bitcoin',
        ),
      );
      _logger?.info(
        'BitcoinWallet',
        'Outgoing BTC tx persisted: txid=$txid amount=$amountSats',
      );
    } catch (e, st) {
      _logger?.error(
        'BitcoinWallet',
        'Failed to persist outgoing BTC tx $txid (broadcast already succeeded)',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ─────────────────────────────────────────── balance

  @override
  TaskEither<WalletError, Balance> getBalance() {
    return TaskEither.tryCatch(
      () async {
        final Balance balance = {};

        // The Liquid service holds every Liquid asset (L-BTC, USDt, DePix).
        final liquid = _liquid;
        if (liquid != null) {
          final r = await _safe(liquid.getBalance);
          r.fold(
            (err) => _debug('[getBalance] Liquid balance failed: $err'),
            (b) {
              for (final a in b.assets) {
                if (a.chain != ChainId.liquid) continue;
                final asset = _knownLiquidAsset(a.assetId);
                // NOTE(core): the old impl mapped an unknown asset id to
                // `Asset.btc` (via `Asset.fromId`). It is skipped here so
                // it cannot show up as on-chain BTC.
                if (asset == null) continue;
                balance[asset] = (balance[asset] ?? BigInt.zero) +
                    BigInt.from(a.amountSat);
              }
            },
          );
        }

        final bitcoin = _bitcoin;
        if (bitcoin != null) {
          final r = await _safe(bitcoin.getBalance);
          r.fold(
            (err) => _debug('[getBalance] Bitcoin balance failed: $err'),
            // NOTE(core): the old impl used BDK `trustedSpendable`. The
            // service exposes the total and a pending part only. The total
            // is used, as the V2 home balance does.
            (b) => balance[Asset.btc] =
                BigInt.from(b.totalSatForChain(ChainId.bitcoin)),
          );
        } else {
          _debug('[getBalance] Bitcoin wallet not available');
        }

        return balance;
      },
      (error, stackTrace) => WalletError(
        WalletErrorType.sdkError,
        'Failed to get balance: $error',
      ),
    );
  }

  /// The legacy asset for a Liquid balance entry. A null id is L-BTC.
  static Asset? _knownLiquidAsset(String? assetId) {
    if (assetId == null) return Asset.lbtc;
    return switch (assetId) {
      lbtcAssetId => Asset.lbtc,
      usdtAssetId => Asset.usdt,
      depixAssetId => Asset.depix,
      _ => null,
    };
  }

  // ─────────────────────────────────────────── transactions

  @override
  TaskEither<WalletError, List<Transaction>> getTransactions({
    TransactionType? type,
    TransactionStatus? status,
    Asset? asset,
    Blockchain? blockchain,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TaskEither.tryCatch(
      () async {
        final results = await Future.wait([
          _liquidTransactions(),
          _bitcoinTransactions(),
        ]);

        Iterable<Transaction> filter(List<Transaction> txs) =>
            applyLegacyTransactionFilters(
              txs,
              type: type,
              status: status,
              asset: asset,
              blockchain: blockchain,
              startDate: startDate,
              endDate: endDate,
            );

        final liquidTxs = filter(results[0]).toList();
        final btcTxs = filter(results[1]).toList();

        final processed = mergeAndIdentifyInternalSwaps(liquidTxs, btcTxs);

        // Persist internal-Liquid swaps found by the matcher into the
        // immutable Swaps table. Idempotent, and fail-open inside the repo.
        await _persistInternalSwaps(processed);

        return processed;
      },
      (error, stackTrace) =>
          WalletError(WalletErrorType.sdkError, error.toString()),
    );
  }

  Future<List<Transaction>> _liquidTransactions() async {
    final liquid = _liquid;
    if (liquid == null) return const [];
    final r = await _safe(liquid.listTransactions);
    return r.fold(
      (err) {
        _debug('Error fetching liquid transactions: $err');
        return const [];
      },
      (txs) => [
        for (final t in txs)
          if (t.chain == ChainId.liquid) _liquidRow(t),
      ],
    );
  }

  Future<List<Transaction>> _bitcoinTransactions() async {
    final bitcoin = _bitcoin;
    if (bitcoin == null) return const [];
    // NOTE(core): the old impl ran a blocking BDK electrum sync before it
    // read the history. The services sync on the orchestrator schedule, so
    // this reads the service's current list.
    final r = await _safe(bitcoin.listTransactions);
    final txs = r.fold(
      (err) {
        _debug('Error fetching bitcoin transactions: $err');
        return const <v2.Transaction>[];
      },
      (txs) => txs.where((t) => t.chain == ChainId.bitcoin).toList(),
    );
    if (txs.isEmpty) return const [];

    // The old rows carried the BDK confirmation height. V2 rows carry the
    // confirmation count, so the height comes back from the chain tip.
    final tip = txs.any((t) => t.confirmations > 0)
        ? (await _safe(bitcoin.getBlockHeight)).toNullable()
        : null;
    return [for (final t in txs) _bitcoinRow(t, tip)];
  }

  static Transaction _liquidRow(v2.Transaction t) {
    final row = legacyTransactionFromV2(t);
    // NOTE(core): the old impl used the LWK `unblindedUrl` when present.
    // The V2 transaction has no unblinding data, so the link always uses
    // the plain txid form (the old fallback).
    return _copyWith(
      row,
      blockchainUrl: 'https://blockstream.info/liquid/tx/${t.id}',
    );
  }

  static Transaction _bitcoinRow(v2.Transaction t, int? tip) {
    final row = legacyTransactionFromV2(t);
    final height = (tip != null &&
            t.status == v2.TransactionStatus.confirmed &&
            t.confirmations > 0)
        ? tip - t.confirmations + 1
        : null;
    return height == null ? row : _copyWith(row, confirmationHeight: height);
  }

  static Transaction _copyWith(
    Transaction t, {
    String? blockchainUrl,
    int? confirmationHeight,
  }) {
    return Transaction(
      id: t.id,
      amount: t.amount,
      blockchain: t.blockchain,
      asset: t.asset,
      type: t.type,
      status: t.status,
      createdAt: t.createdAt,
      fromAsset: t.fromAsset,
      toAsset: t.toAsset,
      sentAmount: t.sentAmount,
      receivedAmount: t.receivedAmount,
      sendTxId: t.sendTxId,
      receiveTxId: t.receiveTxId,
      sendBlockchain: t.sendBlockchain,
      receiveBlockchain: t.receiveBlockchain,
      confirmationHeight: confirmationHeight ?? t.confirmationHeight,
      preimage: t.preimage,
      blockchainUrl: blockchainUrl ?? t.blockchainUrl,
      destination: t.destination,
      feesSat: t.feesSat,
    );
  }

  /// Same as `WalletRepositoryImpl._persistInternalSwaps`.
  Future<void> _persistInternalSwaps(List<Transaction> processed) async {
    final audit = _swapAudit;
    if (audit == null) return;

    for (final tx in processed) {
      if (tx.type != TransactionType.swap) continue;
      if (tx.sendTxId == null || tx.receiveTxId == null) continue;
      if (tx.sendBlockchain == Blockchain.bitcoin ||
          tx.receiveBlockchain == Blockchain.bitcoin) {
        continue;
      }

      await audit.recordCompleted(
        provider: 'internal_liquid',
        direction: 'asset_swap',
        sendAsset: tx.fromAsset?.id ?? 'unknown',
        receiveAsset: tx.toAsset?.id ?? 'unknown',
        sendAmount: tx.sentAmount ?? tx.amount,
        receiveAmount: tx.receivedAmount ?? tx.amount,
        txId: tx.sendTxId,
        metadata: {
          'sendTxId': tx.sendTxId,
          'receiveTxId': tx.receiveTxId,
          'status': tx.status.name,
        },
      );
    }
  }

  // ─────────────────────────────────────────── receive addresses

  @override
  TaskEither<WalletError, String> getBitcoinReceiveAddress() {
    return _bitcoinReceiveAddress();
  }

  TaskEither<WalletError, String> _bitcoinReceiveAddress() {
    return _withBitcoin(
      (btc) => _service(
        () => btc.nextReceiveAddress(),
        (m) => WalletError(WalletErrorType.sdkError, m),
      ).flatMap((r) {
        final address = r.address;
        if (address == null || address.isEmpty) {
          return TaskEither.left(
            const WalletError(WalletErrorType.sdkError, 'empty address'),
          );
        }
        return TaskEither.right(address);
      }),
    );
  }

  @override
  TaskEither<WalletError, String> getLiquidReceiveAddress() {
    return _withLiquid(
      (liquid) => _service(
        liquid.getReceiveAddress,
        (m) => WalletError(
          WalletErrorType.sdkError,
          'Erro ao obter endereço Liquid: $m',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── chain metadata

  @override
  TaskEither<WalletError, int> getCurrentBitcoinBlockHeight() {
    return _withBitcoin(
      (btc) => _service(
        btc.getBlockHeight,
        (m) => WalletError(
          WalletErrorType.networkError,
          'Erro ao obter altura do bloco Bitcoin: $m',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── swap surface

  @override
  TaskEither<WalletError, List<v2.LiquidUtxo>> getLiquidUtxos() {
    return _withLiquid(
      (liquid) => _service(
        liquid.getUtxos,
        (m) => WalletError(
          WalletErrorType.sdkError,
          'Erro ao listar UTXOs Liquid: $m',
        ),
      ),
    );
  }

  @override
  TaskEither<WalletError, String> signSwapPset({
    required String pset,
    required String mnemonic,
  }) {
    return _withLiquid(
      (liquid) => _service(
        () => liquid.signSwapPset(pset: pset, mnemonic: mnemonic),
        (m) => WalletError(
          WalletErrorType.transactionFailed,
          'Erro ao assinar PSET de swap: $m',
        ),
      ),
    );
  }

  @override
  TaskEither<WalletError, String> getLiquidSwapAddress() {
    return _withLiquid(
      (liquid) => _service(
        liquid.getReceiveAddress,
        (m) => WalletError(
          WalletErrorType.sdkError,
          'Erro ao obter endereço Liquid para swap: $m',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── helpers

  static SendRequest _bitcoinRequest({
    required String destination,
    required BigInt amountSat,
    bool drain = false,
    int? feeRateSatPerVByte,
  }) {
    return SendRequest(
      chain: ChainId.bitcoin,
      destination: destination,
      amountSat: amountSat.toInt(),
      drain: drain,
      feeRateOverrideSatPerVByte: feeRateSatPerVByte?.toDouble(),
    );
  }

  /// The old impl returned `invalidAddress` when BDK could not parse the
  /// destination and `transactionFailed` for every other build error.
  ///
  /// NOTE(core): the service reports both as a [ServiceFailure] message,
  /// so the kind comes from the message text.
  static WalletError _bitcoinBuildError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('address')) {
      return WalletError(WalletErrorType.invalidAddress, message);
    }
    return WalletError(WalletErrorType.transactionFailed, message);
  }

  /// The old impl returned `connectionError` when the broadcast failed and
  /// the build kinds for build or sign errors.
  static WalletError _bitcoinSendError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('broadcast') || lower.contains('electrum')) {
      return WalletError(WalletErrorType.connectionError, message);
    }
    return _bitcoinBuildError(message);
  }

  /// Calls [call] and turns a thrown error into a [Left].
  static Future<Either<Object, T>> _safe<T>(
    Future<Either<ServiceFailure, T>> Function() call,
  ) async {
    try {
      return (await call()).mapLeft<Object>((f) => f);
    } catch (e) {
      return Left(e);
    }
  }

  static void _debug(String message) {
    if (kDebugMode) debugPrint('[ServiceBackedWalletRepository] $message');
  }
}

// ─────────────────────────────────────────── pure helpers

/// Applies the legacy `getTransactions` filters.
///
/// Date bounds are exclusive, as in `LiquidWallet._applyFilters`.
///
/// NOTE(core): the old Liquid filter compared milliseconds with
/// microseconds, so `startDate` dropped every row and `endDate` dropped
/// none, and the old Bitcoin path did not filter at all. Here every filter
/// applies to both chains and both dates compare in milliseconds.
@visibleForTesting
Iterable<Transaction> applyLegacyTransactionFilters(
  Iterable<Transaction> transactions, {
  TransactionType? type,
  TransactionStatus? status,
  Asset? asset,
  Blockchain? blockchain,
  DateTime? startDate,
  DateTime? endDate,
}) {
  return transactions.where((tx) {
    if (asset != null && tx.asset != asset) return false;
    if (blockchain != null && tx.blockchain != blockchain) return false;
    if (type != null && tx.type != type) return false;
    if (status != null && tx.status != status) return false;
    final ms = tx.createdAt.millisecondsSinceEpoch;
    if (startDate != null && ms <= startDate.millisecondsSinceEpoch) {
      return false;
    }
    if (endDate != null && ms >= endDate.millisecondsSinceEpoch) {
      return false;
    }
    return true;
  });
}

/// Merges both chains newest first and pairs BTC <-> L-BTC send/receive
/// legs into one swap row.
///
/// Same algorithm as `_processTransactionsInIsolate` and
/// `_identifyInternalSwapsStatic` in `wallet_repository_impl.dart`, which
/// are private to that file. It runs inline: the list is small and the
/// isolate copy costs more than the work.
@visibleForTesting
List<Transaction> mergeAndIdentifyInternalSwaps(
  List<Transaction> liquidTxs,
  List<Transaction> btcTxs,
) {
  final transactions = [...liquidTxs, ...btcTxs]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final result = <Transaction>[];
  final processedIds = <String>{};
  final minAmount = BigInt.from(25000);
  const maxSwapDuration = Duration(hours: 12);

  for (var i = 0; i < transactions.length; i++) {
    final tx1 = transactions[i];
    if (processedIds.contains(tx1.id)) continue;

    if (tx1.type != TransactionType.send) {
      result.add(tx1);
      continue;
    }

    var foundSwapPair = false;
    for (var j = 0; j < transactions.length; j++) {
      if (j == i || processedIds.contains(transactions[j].id)) continue;
      final tx2 = transactions[j];
      if (tx2.type != TransactionType.receive) continue;

      final isBtcToLbtc = tx1.asset == Asset.btc &&
          tx2.asset == Asset.lbtc &&
          tx1.blockchain == Blockchain.bitcoin &&
          tx2.blockchain == Blockchain.liquid;
      final isLbtcToBtc = tx1.asset == Asset.lbtc &&
          tx2.asset == Asset.btc &&
          tx1.blockchain == Blockchain.liquid &&
          tx2.blockchain == Blockchain.bitcoin;
      if (!isBtcToLbtc && !isLbtcToBtc) continue;

      final sent = tx1.amount;
      final received = tx2.amount;
      final minExpected = (sent * BigInt.from(90)) ~/ BigInt.from(100);
      final maxExpected = (sent * BigInt.from(101)) ~/ BigInt.from(100);
      final hasValidAmount = sent >= minAmount &&
          received >= minExpected &&
          received <= maxExpected;
      final within =
          tx1.createdAt.difference(tx2.createdAt).abs() <= maxSwapDuration;

      if (hasValidAmount && within) {
        result.add(
          Transaction(
            id: '${tx1.id}_${tx2.id}_swap',
            amount: tx2.amount,
            blockchain: tx2.blockchain,
            asset: tx2.asset,
            type: TransactionType.swap,
            status: tx1.status == TransactionStatus.confirmed &&
                    tx2.status == TransactionStatus.confirmed
                ? TransactionStatus.confirmed
                : TransactionStatus.pending,
            createdAt: tx1.createdAt.isBefore(tx2.createdAt)
                ? tx1.createdAt
                : tx2.createdAt,
            fromAsset: tx1.asset,
            toAsset: tx2.asset,
            sentAmount: tx1.amount,
            receivedAmount: tx2.amount,
            sendTxId: tx1.id,
            receiveTxId: tx2.id,
            sendBlockchain: tx1.blockchain,
            receiveBlockchain: tx2.blockchain,
          ),
        );
        processedIds
          ..add(tx1.id)
          ..add(tx2.id);
        foundSwapPair = true;
        break;
      }
    }

    if (!foundSwapPair) result.add(tx1);
  }

  return result;
}
