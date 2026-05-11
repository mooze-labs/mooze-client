import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:lwk/lwk.dart' as lwk;

import '../../domain/entities/balance.dart' as domain;
import '../../domain/entities/chain.dart';
import '../../domain/entities/liquid_utxo.dart' as domain;
import '../../domain/entities/transaction.dart' as domain;
import '../../domain/entities/wallet_credentials.dart';
import '../../domain/events/sync_outcome.dart';
import '../../domain/events/transaction_event.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/wallet_directory_guard.dart';
import '../../domain/services/liquid_wallet_service.dart';
import '../../domain/services/service_state.dart';
import '../../shared/clock/clock.dart';
import '../../shared/concurrency/mutex.dart';
import '../../shared/logging/structured_logger.dart';
import '../../shared/streams/replay_value_stream.dart';

/// Production LWK adapter. Owns the wallet handle and the per-wallet
/// `lwk-db` working directory. Connect/disconnect are mutex-gated.
class LiquidWalletServiceImpl implements LiquidWalletService {
  LiquidWalletServiceImpl({
    required this.directoryGuard,
    required this.logger,
    required this.clock,
    this.electrumUrl = 'blockstream.info:995',
    this.validateDomain = true,
    this.workingDirRelative = 'lwk-db',
  });

  final WalletDirectoryGuard directoryGuard;
  final StructuredLogger logger;
  final Clock clock;
  final String electrumUrl;
  final bool validateDomain;
  final String workingDirRelative;

  final Mutex _connectMutex = Mutex();
  final Mutex _syncMutex = Mutex();

  lwk.Wallet? _wallet;
  String? _acquiredDirectory;
  AppNetwork _network = AppNetwork.mainnet;

  /// Set by `disconnect()` BEFORE it queues on `_connectMutex`. An
  /// in-flight `connect()` checks this at every safe yield point and
  /// bails early — releasing the directory guard and the mutex — so
  /// `disconnect()` can run instead of waiting 45s for a wedged
  /// `lwk.Wallet.init`. Reset to `false` at the start of every
  /// `connect()` so subsequent re-imports work.
  bool _shuttingDown = false;

  /// Last-seen transaction identity → used for emitting [TransactionEvent].
  final Map<String, _TxFingerprint> _seen = {};
  List<domain.Transaction> _lastList = const [];
  domain.Balance _lastBalance = domain.Balance.empty();

  final ReplayValueStream<ServiceState> _state =
      ReplayValueStream<ServiceState>.seeded(ServiceState.initial);
  final StreamController<TransactionEvent> _txController =
      StreamController<TransactionEvent>.broadcast();

  @override
  ChainId get chain => ChainId.liquid;
  @override
  Stream<ServiceState> get state => _state.stream;
  @override
  ServiceState get currentState => _state.value;
  @override
  Stream<TransactionEvent> get transactions => _txController.stream;

  @override
  Future<Either<ServiceFailure, Unit>> connect(
      WalletCredentials credentials) async {
    final tEnter = clock.now();
    logger.info('liquid.connect.enter', {});
    return _connectMutex.protect(() async {
      final tProtect = clock.now();
      logger.info('liquid.connect.mutex_acquired', {
        'wait_ms': tProtect.difference(tEnter).inMilliseconds,
      });
      // Fresh attempt clears any stale shutdown signal from a prior
      // delete-and-reimport flow.
      _shuttingDown = false;
      if (currentState.isOperational) {
        logger.info('liquid.connect.short_circuit', {'reason': 'operational'});
        return const Right(unit);
      }
      _emit(ServiceLifecycle.connecting);
      _network = credentials.network;

      final tDirStart = clock.now();
      final dirResult = await directoryGuard.acquire(workingDirRelative);
      logger.info('liquid.connect.dir_acquired', {
        'duration_ms': clock.now().difference(tDirStart).inMilliseconds,
        'left': dirResult.isLeft(),
      });
      if (_shuttingDown) {
        if (dirResult.isRight()) {
          await directoryGuard.release(workingDirRelative);
        }
        return _fail('connect cancelled: shutdown in progress');
      }
      if (dirResult.isLeft()) {
        return _fail('workdir acquire failed: '
            '${dirResult.swap().getOrElse((_) => const StorageFailure("?")).message}');
      }
      _acquiredDirectory =
          dirResult.getOrElse((_) => throw StateError('unreachable'));
      logger.info('liquid.connect.dbpath',
          {'dbpath': _acquiredDirectory ?? '?'});

      try {
        final tDescStart = clock.now();
        final descriptor = await lwk.Descriptor.newConfidential(
          network: _toLwkNetwork(_network),
          mnemonic: credentials.mnemonic,
        );
        logger.info('liquid.connect.descriptor_built', {
          'duration_ms': clock.now().difference(tDescStart).inMilliseconds,
        });
        if (_shuttingDown) {
          await directoryGuard.release(workingDirRelative);
          _acquiredDirectory = null;
          return _fail('connect cancelled: shutdown in progress');
        }
        final tInitStart = clock.now();
        logger.info('liquid.connect.wallet_init.begin',
            {'dbpath': _acquiredDirectory ?? '?'});
        final wallet = await lwk.Wallet.init(
          network: _toLwkNetwork(_network),
          dbpath: _acquiredDirectory!,
          descriptor: descriptor,
        );
        logger.info('liquid.connect.wallet_init.end', {
          'duration_ms': clock.now().difference(tInitStart).inMilliseconds,
        });
        if (_shuttingDown) {
          // FFI returned but shutdown was signalled while we were in it.
          // Discard the freshly initialised wallet and release the slot.
          await directoryGuard.release(workingDirRelative);
          _acquiredDirectory = null;
          return _fail('connect cancelled: shutdown in progress');
        }
        _wallet = wallet;
        _emit(ServiceLifecycle.connected, clearFailure: true);
        logger.info('liquid.connected', {
          'total_ms': clock.now().difference(tEnter).inMilliseconds,
        });
        return const Right(unit);
      } catch (e, st) {
        logger.warn('liquid.connect.threw',
            {'error': '$e', 'after_ms': clock.now().difference(tEnter).inMilliseconds},
            error: e, stackTrace: st);
        await directoryGuard.release(workingDirRelative);
        _acquiredDirectory = null;
        return _fail('lwk init failed: $e', cause: e, stackTrace: st);
      }
    });
  }

  @override
  Future<Either<ServiceFailure, Unit>> disconnect() async {
    // Set BEFORE queueing on `_connectMutex` so an in-flight `connect()`
    // observes the flag at its next yield point and bails — freeing the
    // mutex slot we are about to wait on.
    _shuttingDown = true;
    return _connectMutex.protect(() async {
      final lc = currentState.lifecycle;
      if (lc == ServiceLifecycle.disconnected ||
          lc == ServiceLifecycle.uninitialized) {
        return const Right(unit);
      }
      _emit(ServiceLifecycle.disconnecting);
      try {
        // LWK wallet has no explicit close; releasing the FFI handle and
        // the workdir lock is sufficient.
        _wallet = null;
        _seen.clear();
        if (_acquiredDirectory != null) {
          await directoryGuard.release(workingDirRelative);
          _acquiredDirectory = null;
        }
        _emit(ServiceLifecycle.disconnected, clearFailure: true);
        logger.info('liquid.disconnected', {});
        return const Right(unit);
      } catch (e, st) {
        return _fail('lwk disconnect failed: $e', cause: e, stackTrace: st);
      }
    });
  }

  @override
  Future<Either<ServiceFailure, SyncOutcome>> sync({Duration? timeout}) async {
    return _syncMutex.protect(() async {
      final w = _wallet;
      if (w == null || !currentState.isOperational) {
        return Left(ServiceFailure('not connected', chain: chain));
      }
      final t0 = clock.now();
      try {
        await w
            .sync_(electrumUrl: electrumUrl, validateDomain: validateDomain)
            .timeout(timeout ?? const Duration(seconds: 60));

        final txs = await w.txs();
        final balances = await w.balances();

        final mapped = txs.map(_mapTx).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final changed = _diffAndEmit(mapped);
        _lastList = mapped;
        _lastBalance = _mapBalance(balances);

        _emit(ServiceLifecycle.connected,
            lastSyncAt: clock.now(), clearFailure: true);

        return Right(SyncOutcome(
          chain: chain,
          fetched: mapped.length,
          changed: changed,
          duration: clock.now().difference(t0),
        ));
      } on TimeoutException catch (e, st) {
        return Left(ServiceFailure('lwk sync timeout',
            chain: chain, cause: e, stackTrace: st));
      } catch (e, st) {
        return Left(ServiceFailure('lwk sync failed: $e',
            chain: chain, cause: e, stackTrace: st));
      }
    });
  }

  @override
  Future<Either<ServiceFailure, List<domain.Transaction>>>
      listTransactions() async {
    if (currentState.isOperational) {
      return Right(_lastList);
    }
    return Left(ServiceFailure('not connected', chain: chain));
  }

  @override
  Future<Either<ServiceFailure, domain.Balance>> getBalance() async {
    final w = _wallet;
    if (w == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final balances = await w.balances();
      _lastBalance = _mapBalance(balances);
      return Right(_lastBalance);
    } catch (e, st) {
      return Left(ServiceFailure('lwk balance failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  // ─────────────────────────────────────────── swap surface
  //
  // PSET signing + UTXO enumeration for the SideSwap PayJoin flow.
  // Required because Breez Liquid SDK (which handles regular Liquid
  // sends) does not expose raw PSET signing — only the LWK wallet
  // handle holds the private keys needed for that. Caller (the swap
  // repository) supplies the mnemonic per-call so this service stays
  // stateless about credentials.

  @override
  Future<Either<ServiceFailure, List<domain.LiquidUtxo>>> getUtxos() async {
    final w = _wallet;
    if (w == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final utxos = await w.utxos();
      final mapped = utxos
          .map((u) => domain.LiquidUtxo(
                txid: u.outpoint.txid,
                vout: u.outpoint.vout,
                assetId: u.unblinded.asset,
                assetBlindingFactor: u.unblinded.assetBf,
                valueSat: u.unblinded.value,
                valueBlindingFactor: u.unblinded.valueBf,
              ))
          .toList();
      return Right(mapped);
    } catch (e, st) {
      return Left(ServiceFailure('lwk getUtxos failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<ServiceFailure, String>> signSwapPset({
    required String pset,
    required String mnemonic,
  }) async {
    final w = _wallet;
    if (w == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final signed = await w.signedPsetWithExtraDetails(
        network: _toLwkNetwork(_network),
        pset: pset,
        mnemonic: mnemonic,
      );
      return Right(signed);
    } catch (e, st) {
      return Left(ServiceFailure('lwk signSwapPset failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<ServiceFailure, String>> getReceiveAddress() async {
    final w = _wallet;
    if (w == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final address = await w.addressLastUnused();
      return Right(address.confidential);
    } catch (e, st) {
      return Left(ServiceFailure('lwk getReceiveAddress failed: $e',
          chain: chain, cause: e, stackTrace: st));
    }
  }

  // ─────────────────────────────────────────── helpers

  void _emit(ServiceLifecycle l,
      {DateTime? lastSyncAt, ServiceFailure? failure, bool clearFailure = false}) {
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
    logger.warn('liquid.fail', {'reason': msg});
    return Left(f);
  }

  lwk.Network _toLwkNetwork(AppNetwork n) => switch (n) {
        AppNetwork.mainnet => lwk.Network.mainnet,
        AppNetwork.testnet => lwk.Network.testnet,
        AppNetwork.regtest => lwk.Network.testnet,
      };

  /// Translates an LWK [Tx] into a domain [Transaction]. The `kind` field
  /// can be 'incoming' / 'outgoing' / 'unknown'.
  domain.Transaction _mapTx(lwk.Tx t) {
    final dir = switch (t.kind) {
      'incoming' => domain.TransactionDirection.incoming,
      'outgoing' => domain.TransactionDirection.outgoing,
      _ => domain.TransactionDirection.internal,
    };
    final status = t.height == null
        ? domain.TransactionStatus.pending
        : domain.TransactionStatus.confirmed;
    final ts = t.timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(t.timestamp! * 1000)
        : clock.now();
    final amount = t.balances.isEmpty
        ? 0
        : t.balances.first.value
            .toInt()
            .abs();
    final assetId = t.balances.isEmpty ? null : t.balances.first.assetId;
    return domain.Transaction(
      id: t.txid,
      chain: chain,
      direction: dir,
      status: status,
      amountSat: amount,
      feeSat: t.fee.toInt(),
      timestamp: ts,
      confirmations: t.height == null ? 0 : 1,
      assetId: assetId,
    );
  }

  domain.Balance _mapBalance(List<lwk.Balance> balances) {
    final assets = balances
        .map((b) => domain.AssetBalance(
              chain: chain,
              assetId: b.assetId,
              amountSat: b.value.toInt(),
            ))
        .toList();
    return domain.Balance(assets: assets, snapshotAt: clock.now());
  }

  int _diffAndEmit(List<domain.Transaction> incoming) {
    var changes = 0;
    final now = clock.now();
    for (final tx in incoming) {
      final prev = _seen[tx.id];
      if (prev == null) {
        changes++;
        _seen[tx.id] = _TxFingerprint(tx.status, tx.confirmations);
        _emitTx(TransactionEvent(
          kind: TransactionEventKind.created,
          transaction: tx,
          observedAt: now,
        ));
        continue;
      }
      if (prev.status != tx.status) {
        changes++;
        _seen[tx.id] = _TxFingerprint(tx.status, tx.confirmations);
        _emitTx(TransactionEvent(
          kind: TransactionEventKind.statusChanged,
          transaction: tx,
          previousStatus: prev.status,
          previousConfirmations: prev.confirmations,
          observedAt: now,
        ));
      } else if (prev.confirmations != tx.confirmations) {
        changes++;
        _seen[tx.id] = _TxFingerprint(tx.status, tx.confirmations);
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

class _TxFingerprint {
  const _TxFingerprint(this.status, this.confirmations);
  final domain.TransactionStatus status;
  final int confirmations;
}

// Suppress unused-warning for `Platform` if we ever need to log.
// ignore: unused_element
typedef _UnusedPlatform = Platform;
