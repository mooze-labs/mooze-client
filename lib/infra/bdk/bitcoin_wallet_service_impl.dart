import 'dart:async';

import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/balance.dart' as domain;
import '../../domain/entities/broadcast_result.dart' as domain;
import '../../domain/entities/chain.dart';
import '../../domain/entities/fee_estimate.dart' as domain;
import '../../domain/entities/receive_address.dart' as domain;
import '../../domain/entities/send_request.dart' as domain;
import '../../domain/entities/transaction.dart' as domain;
import '../../domain/entities/wallet_credentials.dart';
import '../../domain/events/sync_outcome.dart';
import '../../domain/events/transaction_event.dart';
import '../../domain/failures/failure.dart';
import '../../domain/services/bitcoin_wallet_service.dart';
import '../../domain/services/service_state.dart';
import '../../shared/clock/clock.dart';
import '../../shared/concurrency/mutex.dart';
import '../../shared/logging/structured_logger.dart';
import '../../shared/streams/replay_value_stream.dart';

class BitcoinWalletServiceImpl implements BitcoinWalletService {
  BitcoinWalletServiceImpl({
    required this.logger,
    required this.clock,
    this.electrumUrl = 'ssl://electrum.blockstream.info:50002',
    this.stopGap = 20,
    this.retry = 5,
    this.timeoutSec = 30,
    this.validateDomain = true,
  });

  final StructuredLogger logger;
  final Clock clock;
  final String electrumUrl;
  final int stopGap;
  final int retry;
  final int timeoutSec;
  final bool validateDomain;

  static const _externalDerivationPath = "m/84h/0h/0h/0";
  static const _internalDerivationPath = "m/84h/0h/0h/1";

  final Mutex _connectMutex = Mutex();
  final Mutex _syncMutex = Mutex();

  bdk.Wallet? _wallet;
  bdk.Blockchain? _blockchain;
  AppNetwork _network = AppNetwork.mainnet;

  final Map<String, _BdkFingerprint> _seen = {};
  List<domain.Transaction> _lastList = const [];
  domain.Balance _lastBalance = domain.Balance.empty();

  final ReplayValueStream<ServiceState> _state =
      ReplayValueStream<ServiceState>.seeded(ServiceState.initial);
  final StreamController<TransactionEvent> _txController =
      StreamController<TransactionEvent>.broadcast();

  @override
  ChainId get chain => ChainId.bitcoin;
  @override
  Stream<ServiceState> get state => _state.stream;
  @override
  ServiceState get currentState => _state.value;
  @override
  Stream<TransactionEvent> get transactions => _txController.stream;

  /// Underlying BDK wallet handle. `null` until `connect()` succeeds and
  /// after `disconnect()`. Exposed so legacy `WalletRepositoryImpl/bitcoin.dart`
  /// can reuse the same `bdk.Wallet` instance V2 owns — eliminating the
  /// duplicate-SDK-instance corruption risk that existed when the legacy
  /// `bdkDatasourceProvider` constructed its own wallet.
  ///
  /// Callers MUST NOT mutate this handle directly. The V2 service owns the
  /// wallet's lifecycle; any sync / persistence / fingerprinting goes
  /// through this class.
  bdk.Wallet? get sdkClient => _wallet;

  /// Underlying BDK Electrum blockchain handle. Required by the legacy
  /// `BdkDataSource.sync()` shim. Same constraints as [sdkClient] —
  /// V2 owns the lifecycle.
  bdk.Blockchain? get sdkBlockchain => _blockchain;

  @override
  Future<Either<ServiceFailure, Unit>> connect(
      WalletCredentials credentials) async {
    return _connectMutex.protect(() async {
      if (currentState.isOperational) return const Right(unit);
      _emit(ServiceLifecycle.connecting);
      _network = credentials.network;
      try {
        final mnemonic = await bdk.Mnemonic.fromString(credentials.mnemonic);
        final secret = await bdk.DescriptorSecretKey.create(
          network: _toBdkNetwork(_network),
          mnemonic: mnemonic,
        );
        final externalDesc = await _buildDescriptor(
            secret, _externalDerivationPath, _toBdkNetwork(_network));
        final internalDesc = await _buildDescriptor(
            secret, _internalDerivationPath, _toBdkNetwork(_network));

        final wallet = await bdk.Wallet.create(
          descriptor: externalDesc,
          changeDescriptor: internalDesc,
          network: _toBdkNetwork(_network),
          databaseConfig: const bdk.DatabaseConfig.memory(),
        );

        final blockchain = await bdk.Blockchain.create(
          config: bdk.BlockchainConfig.electrum(
            config: bdk.ElectrumConfig(
              url: electrumUrl,
              retry: retry,
              timeout: timeoutSec,
              stopGap: BigInt.from(stopGap),
              validateDomain: validateDomain,
            ),
          ),
        );

        _wallet = wallet;
        _blockchain = blockchain;
        _emit(ServiceLifecycle.connected, clearFailure: true);
        logger.info('bitcoin.connected', {});
        return const Right(unit);
      } catch (e, st) {
        return _fail('bdk init failed: $e', cause: e, stackTrace: st);
      }
    });
  }

  Future<bdk.Descriptor> _buildDescriptor(
      bdk.DescriptorSecretKey root, String path, bdk.Network network) async {
    final dp = await bdk.DerivationPath.create(path: path);
    final derived = root.derive(dp);
    return bdk.Descriptor.create(
      descriptor: 'wpkh(${derived.toString()})',
      network: network,
    );
  }

  @override
  Future<Either<ServiceFailure, Unit>> disconnect() async {
    return _connectMutex.protect(() async {
      final lc = currentState.lifecycle;
      if (lc == ServiceLifecycle.disconnected ||
          lc == ServiceLifecycle.uninitialized) {
        return const Right(unit);
      }
      _emit(ServiceLifecycle.disconnecting);
      _wallet = null;
      _blockchain = null;
      _seen.clear();
      _emit(ServiceLifecycle.disconnected, clearFailure: true);
      logger.info('bitcoin.disconnected', {});
      return const Right(unit);
    });
  }

  @override
  Future<Either<ServiceFailure, SyncOutcome>> sync({Duration? timeout}) async {
    return _syncMutex.protect(() async {
      final w = _wallet;
      final bc = _blockchain;
      if (w == null || bc == null || !currentState.isOperational) {
        return Left(ServiceFailure('not connected', chain: chain));
      }
      final t0 = clock.now();
      try {
        await w
            .sync(blockchain: bc)
            .timeout(timeout ?? const Duration(seconds: 60));

        final txs = w.listTransactions(includeRaw: false);
        final balance = w.getBalance();

        final mapped = txs.map(_mapTx).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final changed = _diffAndEmit(mapped);
        _lastList = mapped;
        _lastBalance = _mapBalance(balance);

        _emit(ServiceLifecycle.connected,
            lastSyncAt: clock.now(), clearFailure: true);

        return Right(SyncOutcome(
          chain: chain,
          fetched: mapped.length,
          changed: changed,
          duration: clock.now().difference(t0),
        ));
      } on TimeoutException catch (e, st) {
        return Left(ServiceFailure('bdk sync timeout',
            chain: chain, cause: e, stackTrace: st));
      } catch (e, st) {
        return Left(ServiceFailure('bdk sync failed: $e',
            chain: chain, cause: e, stackTrace: st));
      }
    });
  }

  @override
  Future<Either<ServiceFailure, List<domain.Transaction>>>
      listTransactions() async {
    if (currentState.isOperational) return Right(_lastList);
    return Left(ServiceFailure('not connected', chain: chain));
  }

  @override
  Future<Either<ServiceFailure, int>> getBlockHeight() async {
    final bc = _blockchain;
    if (bc == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final height = await bc.getHeight();
      return Right(height);
    } catch (e, st) {
      return Left(ServiceFailure('bdk getHeight failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<ServiceFailure, domain.Balance>> getBalance() async {
    final w = _wallet;
    if (w == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final b = w.getBalance();
      _lastBalance = _mapBalance(b);
      return Right(_lastBalance);
    } catch (e, st) {
      return Left(ServiceFailure('bdk balance failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  // ─────────────────────────────────────────── SpendableWalletService
  //
  // Bitcoin on-chain (`ChainId.bitcoin`) sends route through BDK's
  // TxBuilder + sign + Electrum broadcast pipeline — same path legacy
  // `wallet_repository_impl/bitcoin.dart` uses (`_buildPsbt`,
  // `_signTransaction`, `blockchain.broadcast(...)`). The two-step
  // (estimate then send) hides BDK's TxBuilder behind the V2 contract;
  // unlike Breez, BDK does not require a prepared-token to be threaded
  // between estimate and send — but we re-build inside `sendOnchain` so
  // UTXO selection runs against the current wallet state, not a stale
  // estimate result. Matches legacy semantics.
  //
  // Liquid (`ChainId.liquid`) and Lightning (`ChainId.lightning`) are
  // rejected here — they live on the Breez-backed `LightningWalletService`.

  @override
  Future<Either<ServiceFailure, domain.FeeEstimate>> estimateFee(
      domain.SendRequest request) async {
    if (request.chain != ChainId.bitcoin) {
      return Left(ServiceFailure(
        'bitcoin service only handles Bitcoin on-chain estimates '
        '(got: ${request.chain.name})',
        chain: chain,
      ));
    }
    if (request.assetId != null) {
      return Left(ServiceFailure(
        'bitcoin service does not handle asset sends (got assetId: '
        '${request.assetId})',
        chain: chain,
      ));
    }
    final w = _wallet;
    if (w == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final result = await _buildPsbt(request);
      return result.fold(
        (f) => Left<ServiceFailure, domain.FeeEstimate>(f),
        (psbtTuple) {
          final fee = (psbtTuple.$2.fee ?? BigInt.zero).toInt();
          return Right<ServiceFailure, domain.FeeEstimate>(domain.FeeEstimate(
            chain: ChainId.bitcoin,
            priority: request.feePriority,
            absoluteFeeSat: fee,
            feeRateSatPerVByte: request.feeRateOverrideSatPerVByte,
            // BDK does not surface confirmation-block estimates from the
            // builder. UI shows mempool position / fee absolute only.
          ));
        },
      );
    } catch (e, st) {
      return Left(ServiceFailure('bdk estimateFee failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<ServiceFailure, domain.ReceiveAddress>> nextReceiveAddress({
    String? assetId,
    String? label,
  }) async {
    if (assetId != null) {
      return Left(ServiceFailure(
        'bitcoin service does not handle asset receives (got assetId: '
        '$assetId)',
        chain: chain,
      ));
    }
    final w = _wallet;
    if (w == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      // Walk-forward unused-address logic — ported verbatim from legacy
      // `BitcoinWallet._nextUnusedReceiveAddress`. `AddressIndex.lastUnused()`
      // can return an address that received funds via a prior wallet on the
      // same descriptor (BDK doesn't track that across recreates), so we
      // skip any address whose script appears in current UTXOs OR
      // historical outputs, then `reset(index)` to advance the internal
      // counter past the chosen address.
      final usedScripts = _buildUsedScriptSet(w);
      final last = w.getAddress(addressIndex: bdk.AddressIndex.lastUnused());
      var index = last.index;
      var addrStr = last.address.asString();
      var scriptHex = _scriptHex(last.address.scriptPubkey().bytes);

      const cap = 100;
      var walked = 0;
      while (usedScripts.contains(scriptHex) && walked < cap) {
        index++;
        walked++;
        final info =
            w.getAddress(addressIndex: bdk.AddressIndex.peek(index: index));
        addrStr = info.address.asString();
        scriptHex = _scriptHex(info.address.scriptPubkey().bytes);
      }

      if (usedScripts.contains(scriptHex)) {
        return Left(ServiceFailure(
          'no unused receive address found within $cap-index window',
          chain: chain,
        ));
      }

      // Pin BDK's internal counter past this index so subsequent
      // `.increase()` calls don't return earlier addresses.
      w.getAddress(addressIndex: bdk.AddressIndex.reset(index: index));

      return Right(domain.ReceiveAddress(
        chain: ChainId.bitcoin,
        address: addrStr,
        label: label,
      ));
    } catch (e, st) {
      return Left(ServiceFailure('bdk nextReceiveAddress failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<ServiceFailure, domain.BroadcastResult>> sendOnchain(
      domain.SendRequest request) async {
    if (request.chain != ChainId.bitcoin) {
      return Left(ServiceFailure(
        'bitcoin service only handles Bitcoin on-chain sends '
        '(got: ${request.chain.name})',
        chain: chain,
      ));
    }
    if (request.assetId != null) {
      return Left(ServiceFailure(
        'bitcoin service does not handle asset sends (got assetId: '
        '${request.assetId})',
        chain: chain,
      ));
    }
    final w = _wallet;
    final bc = _blockchain;
    if (w == null || bc == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }

    try {
      // Step 1: rebuild PSBT inside the send path (same as legacy
      // `sendOnchainBitcoinPayment`) so UTXO selection runs against the
      // current wallet state, not a fee-estimate snapshot. This avoids
      // double-spending a UTXO that another flow consumed between
      // estimate and send.
      final buildResult = await _buildPsbt(request);
      final psbtTuple = buildResult.fold<
          ({bdk.PartiallySignedTransaction psbt, bdk.TransactionDetails details})?>(
        (_) => null,
        (t) => (psbt: t.$1, details: t.$2),
      );
      if (psbtTuple == null) {
        return buildResult.fold(
          (f) => Left<ServiceFailure, domain.BroadcastResult>(f),
          (_) => Left<ServiceFailure, domain.BroadcastResult>(
            ServiceFailure('unreachable: build returned right but null tuple',
                chain: chain),
          ),
        );
      }

      // Step 2: sign. `wallet.sign` is synchronous and returns true on
      // success (BDK-Flutter API). A false return means the wallet
      // couldn't sign — most commonly a watch-only descriptor, which we
      // don't support here.
      final signed = w.sign(psbt: psbtTuple.psbt);
      if (!signed) {
        return Left(ServiceFailure(
          'bdk sign returned false (watch-only descriptor?)',
          chain: chain,
        ));
      }

      // Step 3: extract raw tx and broadcast via Electrum. The txid
      // returned here is BDK's deterministic computation from the signed
      // bytes — never null, always a valid 64-char hex string.
      final rawTx = psbtTuple.psbt.extractTx();
      final txid = await bc.broadcast(transaction: rawTx);
      if (txid.isEmpty) {
        return Left(ServiceFailure(
          'bdk broadcast returned empty txid',
          chain: chain,
        ));
      }

      // Step 4: build domain `Transaction` for the synthetic event +
      // BroadcastResult. The amount/fee come from `details` (BDK's
      // structured view of the build); the timestamp is now (the chain
      // doesn't have a confirmation timestamp yet — the next sync tick
      // upgrades `confirmations` from 0 to 1+).
      final feeSat = (psbtTuple.details.fee ?? BigInt.zero).toInt();
      final mapped = domain.Transaction(
        id: txid,
        chain: ChainId.bitcoin,
        direction: domain.TransactionDirection.outgoing,
        status: domain.TransactionStatus.pending,
        amountSat: request.amountSat,
        feeSat: feeSat,
        timestamp: clock.now(),
        confirmations: 0,
        address: request.destination,
        label: request.label,
        source: domain.TransactionSource.bdk,
      );

      // Step 5: persist-before-republish. Same pattern as Liquid: update
      // local view + emit synthetic `TransactionEvent.created` so the
      // orchestrator's `_onTransactionEvent` runs `transactionStore.upsert`
      // BEFORE any UI subscriber observes it. This is the V2 replacement
      // for legacy `BitcoinWallet._persistOutgoingTx` (which wrote
      // directly to the drift Transactions table).
      _seen[mapped.id] =
          _BdkFingerprint(mapped.status, mapped.confirmations);
      _lastList = [mapped, ..._lastList];
      _emitTx(TransactionEvent(
        kind: TransactionEventKind.created,
        transaction: mapped,
        observedAt: clock.now(),
      ));

      return Right(domain.BroadcastResult(
        chain: ChainId.bitcoin,
        txId: txid,
        transaction: mapped,
        feePaidSat: feeSat,
      ));
    } catch (e, st) {
      return Left(ServiceFailure('bdk sendOnchain failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  // ─────────────────────────────────────────── helpers

  void _emit(ServiceLifecycle l,
      {DateTime? lastSyncAt,
      ServiceFailure? failure,
      bool clearFailure = false}) {
    if (_state.isClosed) return;
    _state.add(currentState.copyWith(
      lifecycle: l,
      lastSyncAt: lastSyncAt,
      failure: failure,
      clearFailure: clearFailure,
    ));
  }

  Either<ServiceFailure, T> _fail<T>(String msg,
      {Object? cause, StackTrace? stackTrace}) {
    final f = ServiceFailure(msg,
        chain: chain, cause: cause, stackTrace: stackTrace);
    if (!_state.isClosed) {
      _state.add(currentState.copyWith(
        lifecycle: ServiceLifecycle.errored,
        failure: f,
      ));
    }
    logger.warn('bitcoin.fail', {'reason': msg});
    return Left(f);
  }

  bdk.Network _toBdkNetwork(AppNetwork n) => switch (n) {
        AppNetwork.mainnet => bdk.Network.bitcoin,
        AppNetwork.testnet => bdk.Network.testnet,
        AppNetwork.regtest => bdk.Network.regtest,
      };

  /// Build a PSBT for a [domain.SendRequest]. Routing rules:
  ///
  ///   - `drain` (or legacy `subtractFeeFromAmount`) true → drain:
  ///     `drainWallet().drainTo(...)`. The destination receives the wallet
  ///     balance minus fees; `request.amountSat` is ignored.
  ///   - else → standard: `addRecipient(scriptBuf, amount)`.
  ///   - RBF is always enabled (legacy default).
  ///   - `feeRateOverrideSatPerVByte` → `builder.feeRate(rate.toDouble())`.
  ///     When null, BDK's default fee rate is used (legacy doesn't set a
  ///     priority-derived default either; tracked as a follow-up).
  ///
  /// Returns the resulting `(PartiallySignedTransaction, TransactionDetails)`
  /// pair. The caller is responsible for signing + broadcasting.
  Future<Either<ServiceFailure, (bdk.PartiallySignedTransaction, bdk.TransactionDetails)>>
      _buildPsbt(domain.SendRequest request) async {
    final w = _wallet;
    if (w == null) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final scriptBuf = await bdk.Address.fromString(
        s: request.destination,
        network: w.network(),
      ).then((a) => a.scriptPubkey());

      var builder = bdk.TxBuilder().enableRbf();
      if (request.drain || request.subtractFeeFromAmount) {
        builder = builder.drainWallet().drainTo(scriptBuf);
      } else {
        builder = builder.addRecipient(scriptBuf, BigInt.from(request.amountSat));
      }

      final rateOverride = request.feeRateOverrideSatPerVByte;
      if (rateOverride != null) {
        builder = builder.feeRate(rateOverride);
      }

      final result = await builder.finish(w);
      return Right(result);
    } on bdk.AddressException catch (e, st) {
      return Left(ServiceFailure('invalid address: ${e.toString()}',
          chain: chain, cause: e, stackTrace: st));
    } catch (e, st) {
      return Left(ServiceFailure('bdk build PSBT failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  /// Walk the wallet's UTXOs + historical outputs and collect every script
  /// hex they reference. Used by [nextReceiveAddress] to detect addresses
  /// that already received funds (which BDK's `lastUnused()` may hand back
  /// after a wallet recreate). Ported from legacy `BitcoinWallet`.
  Set<String> _buildUsedScriptSet(bdk.Wallet w) {
    final used = <String>{};
    for (final u in w.listUnspent()) {
      used.add(_scriptHex(u.txout.scriptPubkey.bytes));
    }
    for (final tx in w.listTransactions(includeRaw: true)) {
      final raw = tx.transaction;
      if (raw == null) continue;
      for (final out in raw.output()) {
        used.add(_scriptHex(out.scriptPubkey.bytes));
      }
    }
    return used;
  }

  String _scriptHex(List<int> bytes) {
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write((b & 0xff).toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  /// Classify a BDK transaction.
  ///
  /// **Parity with LWK** (post 2026-05-13 audit). BDK's
  /// `TransactionDetails` exposes `received` and `sent`, both
  /// wallet-side. Self-transfers / consolidations have `received > 0`
  /// AND `sent > 0` with `received ≈ sent - fee` (the change UTXO
  /// equals the inputs minus the network fee). Pre-fix the code
  /// classified those as `outgoing` with `amount = fee`, which is
  /// not strictly wrong but renders as "Sent BTC <fee>" in the home
  /// list — confusing alongside Liquid's new "Redeposit BTC L2"
  /// surface for the same conceptual action. The new logic detects
  /// the self-transfer and maps it to [TransactionDirection.selfTransfer]
  /// so both chains render consistently as "Redeposit" in the UI.
  ///
  /// Decision order:
  ///   1. Both `sent > 0` and `received > 0` with the difference
  ///      equal to (or within a small slack of) the fee → selfTransfer.
  ///   2. `sent > received` → outgoing.
  ///   3. `received > 0` → incoming.
  ///   4. Both zero → internal (defensive; shouldn't happen for txs
  ///      surfaced by BDK).
  ///
  /// Slack handling: BDK fee reporting can be slightly off the
  /// arithmetic `sent - received` (RBF reconstructions, BIP-69
  /// reordering). We allow `|sent - received - fee| <= max(1, fee/100)`
  /// to absorb that without misclassifying.
  domain.Transaction _mapTx(bdk.TransactionDetails t) {
    final received = t.received.toInt();
    final sent = t.sent.toInt();
    final feeSat = (t.fee ?? BigInt.zero).toInt();

    final domain.TransactionDirection direction;
    final int amountSat;
    final String reason;

    if (sent > 0 && received > 0) {
      final delta = sent - received;
      final slack = feeSat > 100 ? feeSat ~/ 100 : 1;
      if ((delta - feeSat).abs() <= slack) {
        direction = domain.TransactionDirection.selfTransfer;
        amountSat = feeSat;
        reason = 'self-transfer-fee-only';
      } else if (sent > received) {
        direction = domain.TransactionDirection.outgoing;
        amountSat = delta.abs();
        reason = 'sent-greater-than-received';
      } else {
        direction = domain.TransactionDirection.incoming;
        amountSat = (received - sent).abs();
        reason = 'received-greater-than-sent';
      }
    } else if (sent > 0) {
      direction = domain.TransactionDirection.outgoing;
      amountSat = sent;
      reason = 'sent-only';
    } else if (received > 0) {
      direction = domain.TransactionDirection.incoming;
      amountSat = received;
      reason = 'received-only';
    } else {
      direction = domain.TransactionDirection.internal;
      amountSat = 0;
      reason = 'both-zero';
    }

    final ct = t.confirmationTime;
    final status = ct == null
        ? domain.TransactionStatus.pending
        : domain.TransactionStatus.confirmed;
    final ts = ct == null
        ? clock.now()
        : DateTime.fromMillisecondsSinceEpoch(ct.timestamp.toInt() * 1000);

    logger.debug('tx.classify', {
      'chain': 'bitcoin',
      'txid': t.txid,
      'received': received,
      'sent': sent,
      'feeSat': feeSat,
      'direction': direction.name,
      'amountSat': amountSat,
      'reason': reason,
    });

    return domain.Transaction(
      id: t.txid,
      chain: chain,
      direction: direction,
      status: status,
      amountSat: amountSat,
      feeSat: feeSat,
      timestamp: ts,
      confirmations: ct == null ? 0 : 1,
      // BDK is the only writer for chain=bitcoin user-initiated
      // sends/receives. Breez peg-in/out swap settlements typically
      // use different (id, chain=bitcoin) keys so no conflict; if
      // they ever overlap, the source-aware merge keeps both views
      // semantically distinct via the priority CASE WHEN.
      source: domain.TransactionSource.bdk,
    );
  }

  domain.Balance _mapBalance(bdk.Balance b) {
    final asset = domain.AssetBalance(
      chain: chain,
      amountSat: b.total.toInt(),
      ticker: 'BTC',
    );
    return domain.Balance(assets: [asset], snapshotAt: clock.now());
  }

  int _diffAndEmit(List<domain.Transaction> incoming) {
    var changes = 0;
    final now = clock.now();
    for (final tx in incoming) {
      final prev = _seen[tx.id];
      if (prev == null) {
        changes++;
        _seen[tx.id] = _BdkFingerprint(tx.status, tx.confirmations);
        _emitTx(TransactionEvent(
          kind: TransactionEventKind.created,
          transaction: tx,
          observedAt: now,
        ));
        continue;
      }
      if (prev.status != tx.status) {
        changes++;
        _seen[tx.id] = _BdkFingerprint(tx.status, tx.confirmations);
        _emitTx(TransactionEvent(
          kind: TransactionEventKind.statusChanged,
          transaction: tx,
          previousStatus: prev.status,
          previousConfirmations: prev.confirmations,
          observedAt: now,
        ));
      } else if (prev.confirmations != tx.confirmations) {
        changes++;
        _seen[tx.id] = _BdkFingerprint(tx.status, tx.confirmations);
        _emitTx(TransactionEvent(
          kind: TransactionEventKind.confirmationsChanged,
          transaction: tx,
          previousStatus: prev.status,
          previousConfirmations: prev.confirmations,
          observedAt: now,
        ));
      }
    }
    return changes;
  }

  void _emitTx(TransactionEvent e) {
    if (!_txController.isClosed) _txController.add(e);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    if (!_txController.isClosed) await _txController.close();
    await _state.close();
  }
}

class _BdkFingerprint {
  const _BdkFingerprint(this.status, this.confirmations);
  final domain.TransactionStatus status;
  final int confirmations;
}
