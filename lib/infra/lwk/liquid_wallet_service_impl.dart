import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:lwk/lwk.dart' as lwk;

import '../../domain/entities/asset.dart' show lbtcAssetId;
import '../../domain/entities/balance.dart' as domain;
import '../../domain/entities/chain.dart';
import '../../domain/entities/liquid_utxo.dart' as domain;
import '../../domain/entities/transaction.dart' as domain;
import '../../domain/entities/wallet_credentials.dart';
import '../../domain/events/sync_outcome.dart';
import '../../domain/events/transaction_event.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/wallet_directory_guard.dart';
import '../../domain/services/electrum_endpoint_resolver.dart';
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
    this.endpointResolver,
    this.electrumUrl = 'blockstream.info:995',
    this.validateDomain = true,
    this.workingDirRelative = 'lwk-db',
  });

  final WalletDirectoryGuard directoryGuard;
  final StructuredLogger logger;
  final Clock clock;

  /// Per-instance Electrum rotation. When non-null the service consults
  /// `resolver.current(ChainId.liquid)` for every sync and reports
  /// success / failure to advance rotation. When null the service falls
  /// back to [electrumUrl] (used by tests and pre-G12 wiring).
  final ElectrumEndpointResolver? endpointResolver;

  /// Fallback endpoint when [endpointResolver] is null. Production wiring
  /// always supplies a resolver; this default exists so tests can
  /// continue to construct the service without one.
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

  /// Underlying LWK wallet handle. `null` until `connect()` succeeds and
  /// after `disconnect()`. Exposed so legacy `WalletRepositoryImpl/liquid.dart`
  /// and `address_explorer_repository_impl.dart` can reuse the same
  /// `lwk.Wallet` instance V2 owns — eliminating the duplicate-SDK-instance
  /// SQLite corruption risk that existed when the legacy
  /// `liquidDataSourceProvider` constructed its own wallet (both would try
  /// to open `${appDocs}/lwk-db` concurrently).
  lwk.Wallet? get sdkClient => _wallet;

  /// Electrum endpoint the service is currently using. Used by the legacy
  /// `LiquidDataSource` bridge for diagnostic display.
  String get currentElectrumUrl =>
      endpointResolver?.current(ChainId.liquid) ?? electrumUrl;

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
        // Bug A diagnostic (2026-05-18): the LWK FFI sometimes wedges
        // between `dbpath` and a return, with no further logs until the
        // boot orchestrator's 45s timeout fires. We can't tell from the
        // current logs *which* FFI call hung — Descriptor.newConfidential
        // (in-memory key derivation, should be ms) or Wallet.init (opens
        // the lwk-db sqlite and may replay the persisted update queue —
        // the suspected culprit). `_withFfiTick` emits a `ffi_tick` log
        // every 5s while a FFI call is in-flight, with `phase` +
        // `elapsed_ms`, so the next reproduction tells us exactly which
        // call is the wedge.
        final tDescStart = clock.now();
        final descriptor = await _withFfiTick(
          phase: 'descriptor_new_confidential',
          body: () => lwk.Descriptor.newConfidential(
            network: _toLwkNetwork(_network),
            mnemonic: credentials.mnemonic,
          ),
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
        final wallet = await _withFfiTick(
          phase: 'wallet_init',
          body: () => lwk.Wallet.init(
            network: _toLwkNetwork(_network),
            dbpath: _acquiredDirectory!,
            descriptor: descriptor,
          ),
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
        final desc = _describeLwkError(e);
        logger.warn('liquid.connect.threw',
            {
              'error': desc,
              'errType': e.runtimeType.toString(),
              'after_ms': clock.now().difference(tEnter).inMilliseconds,
            },
            error: e, stackTrace: st);

        // Self-healing recovery for persisted-state inconsistencies.
        //
        // `lwk_wollet::Wollet::new` replays the on-disk update queue and
        // checks that each update's `wollet_status` matches the
        // in-memory wollet's current status. A previous session that was
        // killed mid-write (no graceful shutdown observer wired in the
        // app's lifecycle) can leave the update queue and the wollet
        // snapshot at inconsistent state hashes — every subsequent cold
        // boot then throws `UpdateOnDifferentStatus` on init and the
        // wallet stays in `errored` indefinitely.
        //
        // The lwk-db is a derived cache: descriptor is rebuilt from the
        // mnemonic on every connect, transactions are repopulated from
        // electrum on the next sync, and no signing material lives in
        // the db. Wiping it once and retrying is therefore a safe
        // recovery — at worst the user pays one sync cycle.
        //
        // Bounded to a single retry per `connect()` call. If the retry
        // also fails the original error path is taken and the chain
        // ends up in `errored`, surfacing via `SyncFailureAlert`.
        if (_isRecoverableLwkPersistenceError(desc)) {
          logger.warn('liquid.connect.recover_attempt', {
            'reason': desc,
            'action': 'wipe-lwk-db-and-retry',
          });
          // Release the current lock so wipe can run cleanly, then
          // wipe, re-acquire, and re-init with the same descriptor.
          await directoryGuard.release(workingDirRelative);
          _acquiredDirectory = null;
          final wipeResult = await directoryGuard.wipe(workingDirRelative);
          if (wipeResult.isLeft()) {
            final f = wipeResult.swap().getOrElse(
                (_) => const StorageFailure('wipe failed'));
            logger.error('liquid.connect.recover_wipe_failed',
                {'reason': f.message});
            return _fail('lwk init failed (wipe recovery failed): $desc',
                cause: e, stackTrace: st);
          }
          logger.info('liquid.connect.recover_wiped', {});
          final reAcquire = await directoryGuard.acquire(workingDirRelative);
          if (reAcquire.isLeft()) {
            final f = reAcquire.swap().getOrElse(
                (_) => const StorageFailure('reacquire failed'));
            return _fail(
                'lwk init failed (re-acquire after wipe failed): ${f.message}',
                cause: e, stackTrace: st);
          }
          _acquiredDirectory =
              reAcquire.getOrElse((_) => throw StateError('unreachable'));
          try {
            final retryStart = clock.now();
            // Rebuild descriptor in this scope — the original was local
            // to the failed `try` block above. Descriptor construction
            // is in-memory only (no fs/network), so re-running it is
            // safe and adds <50ms.
            final retryDescriptor = await lwk.Descriptor.newConfidential(
              network: _toLwkNetwork(_network),
              mnemonic: credentials.mnemonic,
            );
            final wallet = await lwk.Wallet.init(
              network: _toLwkNetwork(_network),
              dbpath: _acquiredDirectory!,
              descriptor: retryDescriptor,
            );
            logger.info('liquid.connect.recover_ok', {
              'duration_ms':
                  clock.now().difference(retryStart).inMilliseconds,
            });
            if (_shuttingDown) {
              await directoryGuard.release(workingDirRelative);
              _acquiredDirectory = null;
              return _fail('connect cancelled: shutdown in progress');
            }
            _wallet = wallet;
            _emit(ServiceLifecycle.connected, clearFailure: true);
            logger.info('liquid.connected', {
              'total_ms': clock.now().difference(tEnter).inMilliseconds,
              'recovered_from': 'lwk-db-wipe',
            });
            return const Right(unit);
          } catch (e2, st2) {
            final desc2 = _describeLwkError(e2);
            logger.error('liquid.connect.recover_failed',
                {'error': desc2, 'errType': e2.runtimeType.toString()},
                error: e2, stackTrace: st2);
            await directoryGuard.release(workingDirRelative);
            _acquiredDirectory = null;
            return _fail('lwk init failed after wipe recovery: $desc2',
                cause: e2, stackTrace: st2);
          }
        }

        await directoryGuard.release(workingDirRelative);
        _acquiredDirectory = null;
        return _fail('lwk init failed: $desc', cause: e, stackTrace: st);
      }
    });
  }

  /// Run an LWK FFI call with a periodic "still in progress" tick log.
  ///
  /// Bug A diagnostic (2026-05-18). LWK FFI calls can hang silently —
  /// the boot orchestrator's 45s budget elapses and we have no way to
  /// tell whether the call took 44.9s or has been wedged for the
  /// entire window. Without a periodic tick, all we get is a single
  /// `service_timeout` log with no granularity.
  ///
  /// This helper races the FFI Future against a 5-second
  /// `Timer.periodic` that emits `liquid.connect.ffi_tick` while the
  /// call is still pending. On normal completion the timer is cancelled
  /// in the `finally` block, so successful calls emit zero tick logs.
  /// On hang, the timer keeps firing until the outer boot timeout
  /// gives up — giving us a precise picture of which phase wedged
  /// and for how long.
  ///
  /// Phase strings used:
  ///   - `descriptor_new_confidential` — `lwk.Descriptor.newConfidential`
  ///   - `wallet_init` — `lwk.Wallet.init`
  Future<T> _withFfiTick<T>({
    required String phase,
    required Future<T> Function() body,
  }) async {
    final start = clock.now();
    bool done = false;
    final ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (done) return;
      logger.warn('liquid.connect.ffi_tick', {
        'phase': phase,
        'elapsed_ms': clock.now().difference(start).inMilliseconds,
      });
    });
    try {
      return await body();
    } finally {
      done = true;
      ticker.cancel();
    }
  }

  /// Returns true if `desc` (the unwrapped `LwkError.msg`) corresponds to
  /// a `lwk_wollet::Error` variant that signals on-disk state has drifted
  /// from the on-disk update queue. These are recoverable by wiping the
  /// db dir and rebuilding from the descriptor + a fresh electrum sync.
  ///
  /// Conservative match list — only variants that are demonstrably
  /// derived-cache problems, not anything that could mask a deeper
  /// issue (e.g. descriptor mismatch, key derivation failure):
  ///
  ///   - `UpdateOnDifferentStatus { wollet_status, update_status }` —
  ///     persisted update at index N expects a wollet state hash that
  ///     no longer matches the snapshot. Confirmed cause of the
  ///     2026-05-12 repro.
  ///   - `UpdateHeightTooOld { update_tip_height, store_tip_height }` —
  ///     persisted update is for a chain tip older than the store's
  ///     own tip. Same root mechanism (mid-write death of a prior
  ///     session); same safe recovery.
  static bool _isRecoverableLwkPersistenceError(String desc) {
    return desc.contains('UpdateOnDifferentStatus') ||
        desc.contains('UpdateHeightTooOld');
  }

  /// Unwrap the message from FFI-thrown errors. `lwk.LwkError` (and the
  /// flutter_rust_bridge-generated equivalents) do not override
  /// `toString()`, so a bare `'$e'` resolves to the useless
  /// `"Instance of 'LwkError'"` — masking the actual Rust panic / sqlite
  /// error / network failure. This helper inspects the runtime type and
  /// extracts `.msg` when present (via the public field on the generated
  /// class) so logs and the propagated `ServiceFailure.message` carry the
  /// real cause.
  ///
  /// Repro (2026-05-12): boot trace showed
  /// `liquid.connect.threw error="Instance of 'LwkError'"` with no clue
  /// what LWK was complaining about — possibly a stale lwk-db file from a
  /// prior delete + re-import, a descriptor/network mismatch, or an
  /// underlying sqlite error. Without the message, triage was blind.
  static String _describeLwkError(Object e) {
    if (e is lwk.LwkError) {
      return 'LwkError(${e.msg})';
    }
    // Some FRB-generated errors are private subclasses (`_$LwkError`) or
    // anonymous frb_exception types; their toString() is also useless.
    // Best-effort extract via dynamic access to a `msg` field if it
    // exists at runtime — this is the same shape the generated class
    // uses.
    try {
      final dynamic dyn = e;
      // ignore: avoid_dynamic_calls
      final msg = dyn.msg;
      if (msg is String && msg.isNotEmpty) {
        return '${e.runtimeType}($msg)';
      }
    } catch (_) {/* not a msg-bearing error */}
    return e.toString();
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
        return _fail('lwk disconnect failed: ${_describeLwkError(e)}',
            cause: e, stackTrace: st);
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
      final url = endpointResolver?.current(ChainId.liquid) ?? electrumUrl;
      try {
        await w
            .sync_(electrumUrl: url, validateDomain: validateDomain)
            .timeout(timeout ?? const Duration(seconds: 60));
        endpointResolver?.reportSuccess(ChainId.liquid);

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
        endpointResolver?.reportFailure(ChainId.liquid, e);
        return Left(ServiceFailure('lwk sync timeout',
            chain: chain, cause: e, stackTrace: st));
      } catch (e, st) {
        endpointResolver?.reportFailure(ChainId.liquid, e);
        return Left(ServiceFailure('lwk sync failed: ${_describeLwkError(e)}',
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
    // Cache-only read. `w.balances()` is async at the dart layer but
    // still serializes against LWK's internal wallet state machine and
    // is needless work when `sync()` already refreshed and persisted
    // `_lastBalance` while holding `_syncMutex`. Cache stays at least as
    // fresh as the most recent successful sync; observers wanting live
    // updates subscribe via `watchBalanceFor`.
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return Right(_lastBalance);
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
      return Left(ServiceFailure('lwk getUtxos failed: ${_describeLwkError(e)}',
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
      return Left(ServiceFailure(
          'lwk signSwapPset failed: ${_describeLwkError(e)}',
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
      return Left(ServiceFailure(
          'lwk getReceiveAddress failed: ${_describeLwkError(e)}',
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

  /// Translates an LWK [Tx] into a domain [Transaction].
  ///
  /// **Classification priority** — strictly ordered, mutually exclusive.
  /// The earlier a branch fires, the higher its precedence. This order
  /// is deliberate: `selfTransfer` MUST come before `swap` so a
  /// fee-only consolidation that happens to touch multiple asset
  /// columns (e.g., consolidating L-BTC + zero-net asset rounds)
  /// doesn't get misclassified as a swap.
  ///
  ///   P1. `t.kind == 'redeposit'`                       → selfTransfer
  ///   P2. `nonZero.isEmpty && feeSat > 0`               → selfTransfer
  ///   P3. single L-BTC entry equal to -feeSat           → selfTransfer
  ///   P4. mixed-sign multi-asset (positive AND negative
  ///       non-zero entries with ≥2 unique asset ids)    → swap
  ///   P5. all non-zero balances > 0                     → incoming
  ///   P6. all non-zero balances < 0                     → outgoing
  ///   P7. anything else                                 → internal
  ///
  /// **Swap detail synthesis (P4)** mirrors the legacy
  /// `wallet_repository_impl/liquid.dart::ToTransaction.type` heuristic
  /// that V2 had previously regressed:
  ///   - `toAssetId`  = largest positive non-L-BTC entry by value
  ///                    (falls back to any positive entry).
  ///   - `fromAssetId`= largest negative non-L-BTC entry by abs value
  ///                    (falls back to any negative entry).
  ///   - `sentAmountSat`     = abs(fromAsset balance value)
  ///   - `receivedAmountSat` = positive value of toAsset balance
  ///   - `amountSat`         = sentAmountSat (headline)
  ///   - `assetId`           = fromAssetId (so consumers reading
  ///                            `tx.assetId` see the "from" side)
  ///
  /// **Amount selection (P5/P6/P7)**: largest abs-value non-zero
  /// balance, preferring non-L-BTC so a "Send 100 USDT" surfaces the
  /// USDT amount rather than the L-BTC fee leg.
  ///
  /// Every decision emits a structured `tx.classify` log entry for
  /// post-hoc triage.
  domain.Transaction _mapTx(lwk.Tx t) {
    final feeSat = t.fee.toInt();
    final status = t.height == null
        ? domain.TransactionStatus.pending
        : domain.TransactionStatus.confirmed;
    final ts = t.timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(t.timestamp! * 1000)
        : clock.now();

    final nonZero = t.balances.where((b) => b.value != 0).toList();
    final positives =
        nonZero.where((b) => b.value > 0).toList(growable: false);
    final negatives =
        nonZero.where((b) => b.value < 0).toList(growable: false);
    final uniqueAssets =
        nonZero.map((b) => b.assetId).toSet();

    final domain.TransactionDirection direction;
    final int amountSat;
    final String? mainAssetId;
    String? fromAssetId;
    String? toAssetId;
    int? sentAmountSat;
    int? receivedAmountSat;
    final String reason;

    // ─── P1: explicit LWK redeposit ────────────────────────────────
    if (t.kind == 'redeposit') {
      direction = domain.TransactionDirection.selfTransfer;
      final subject = _detectSelfTransferSubject(t);
      amountSat = subject?.grossSat ?? feeSat;
      mainAssetId = subject?.assetId ?? lbtcAssetId;
      reason = 'lwk-kind-redeposit';
    }
    // ─── P2: nothing moved net, but a fee was paid ─────────────────
    else if (nonZero.isEmpty && feeSat > 0) {
      direction = domain.TransactionDirection.selfTransfer;
      final subject = _detectSelfTransferSubject(t);
      amountSat = subject?.grossSat ?? feeSat;
      mainAssetId = subject?.assetId ?? lbtcAssetId;
      reason = 'fee-only-empty-balances';
    }
    // ─── P3: single-asset L-BTC self-transfer equal to -fee ────────
    //
    // Net L-BTC change is exactly the fee — i.e., only the fee was paid
    // in L-BTC. Any non-L-BTC asset visible on inputs/outputs is the
    // economic subject of the tx (a self-transfer / redeposit of that
    // asset whose net is zero because send and change both land in our
    // wallet). `_detectSelfTransferSubject` walks the unblinded outputs
    // to recover the gross amount that flowed; if none, this is a pure
    // L-BTC consolidation and we fall back to (lbtc, feeSat).
    else if (nonZero.length == 1 &&
        nonZero.first.assetId == lbtcAssetId &&
        nonZero.first.value == -feeSat &&
        feeSat > 0) {
      direction = domain.TransactionDirection.selfTransfer;
      final subject = _detectSelfTransferSubject(t);
      amountSat = subject?.grossSat ?? feeSat;
      mainAssetId = subject?.assetId ?? lbtcAssetId;
      reason = 'lbtc-balance-equals-neg-fee';
    }
    // ─── P4: mixed-sign multi-asset → swap ─────────────────────────
    //
    // Conditions: both positive AND negative entries exist AND ≥2
    // unique asset ids are involved. The "≥2" constraint rules out
    // the degenerate case where a single asset somehow has both
    // signs (shouldn't happen, but guards against weird LWK output).
    //
    // Note this fires AFTER selfTransfer/redeposit, so a P3 case
    // where lbtc moved by exactly -fee never lands here even if
    // some other asset row had a tiny non-zero residual.
    else if (positives.isNotEmpty &&
        negatives.isNotEmpty &&
        uniqueAssets.length >= 2) {
      final pickFromPositives = positives
          .where((b) => b.assetId != lbtcAssetId)
          .toList(growable: false);
      final pickFromNegatives = negatives
          .where((b) => b.assetId != lbtcAssetId)
          .toList(growable: false);

      final toBal = (pickFromPositives.isNotEmpty
              ? pickFromPositives
              : positives)
          .reduce((a, b) => a.value > b.value ? a : b);
      final fromBal = (pickFromNegatives.isNotEmpty
              ? pickFromNegatives
              : negatives)
          .reduce((a, b) => a.value.abs() > b.value.abs() ? a : b);

      direction = domain.TransactionDirection.swap;
      fromAssetId = fromBal.assetId;
      toAssetId = toBal.assetId;
      sentAmountSat = fromBal.value.abs();
      receivedAmountSat = toBal.value;
      // Headline: the "from" side. Mirrors what users think of as
      // "I swapped X for Y" — X is the amount they sent out.
      amountSat = sentAmountSat;
      mainAssetId = fromAssetId;
      reason = 'mixed-sign-multi-asset';
    }
    // ─── P5: pure incoming ─────────────────────────────────────────
    else if (nonZero.isNotEmpty && nonZero.every((b) => b.value > 0)) {
      final main = _pickMainBalance(nonZero, preferNonLbtc: true);
      direction = domain.TransactionDirection.incoming;
      amountSat = main.value.abs();
      mainAssetId = main.assetId;
      reason = 'all-positive';
    }
    // ─── P6: pure outgoing ─────────────────────────────────────────
    else if (nonZero.isNotEmpty && nonZero.every((b) => b.value < 0)) {
      final main = _pickMainBalance(nonZero, preferNonLbtc: true);
      direction = domain.TransactionDirection.outgoing;
      amountSat = main.value.abs();
      mainAssetId = main.assetId;
      reason = 'all-negative';
    }
    // ─── P7: catch-all (issuance / burn / reissuance / unknown) ────
    else {
      final source = nonZero.isNotEmpty ? nonZero : t.balances;
      if (source.isEmpty) {
        direction = domain.TransactionDirection.internal;
        amountSat = 0;
        mainAssetId = null;
        reason = 'empty';
      } else {
        final main = _pickMainBalance(source, preferNonLbtc: true);
        direction = domain.TransactionDirection.internal;
        amountSat = main.value.abs();
        mainAssetId = main.assetId;
        reason = 'fallback';
      }
    }

    logger.debug('tx.classify', {
      'chain': 'liquid',
      'txid': t.txid,
      'lwkKind': t.kind,
      'balanceCount': t.balances.length,
      'nonZeroCount': nonZero.length,
      'uniqueAssets': uniqueAssets.length,
      'direction': direction.name,
      'amountSat': amountSat,
      'feeSat': feeSat,
      'mainAssetId': _assetIdLabel(mainAssetId),
      if (fromAssetId != null) 'fromAsset': _assetIdLabel(fromAssetId),
      if (toAssetId != null) 'toAsset': _assetIdLabel(toAssetId),
      if (sentAmountSat != null) 'sentAmountSat': sentAmountSat,
      if (receivedAmountSat != null)
        'receivedAmountSat': receivedAmountSat,
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
      confirmations: t.height == null ? 0 : 1,
      assetId: mainAssetId,
      fromAssetId: fromAssetId,
      toAssetId: toAssetId,
      sentAmountSat: sentAmountSat,
      receivedAmountSat: receivedAmountSat,
      // LWK is the authoritative source for chain=liquid. The source
      // tag tells the upsert merge that subsequent non-LWK writes
      // (from Breez seeing the same descriptor) MUST NOT overwrite
      // direction/status/amountSat/feeSat/confirmations/assetId/timestamp.
      source: domain.TransactionSource.lwk,
    );
  }

  String _assetIdLabel(String? id) {
    if (id == null) return 'null';
    if (id == lbtcAssetId) return 'lbtc';
    return id.length > 8 ? id.substring(0, 8) : id;
  }


  ({String assetId, int grossSat})? _detectSelfTransferSubject(lwk.Tx t) {
    final candidates = <String>{};
    for (final b in t.balances) {
      if (b.assetId != lbtcAssetId) candidates.add(b.assetId);
    }
    for (final o in t.outputs) {
      if (o.unblinded.asset != lbtcAssetId) candidates.add(o.unblinded.asset);
    }
    for (final i in t.inputs) {
      if (i.unblinded.asset != lbtcAssetId) candidates.add(i.unblinded.asset);
    }
    if (candidates.isEmpty) return null;

    String? winner;
    int winnerGross = 0;
    for (final id in candidates) {
      final inSum = t.inputs
          .where((o) => o.unblinded.asset == id)
          .fold<int>(0, (s, o) => s + o.unblinded.value.toInt());
      final outSum = t.outputs
          .where((o) => o.unblinded.asset == id)
          .fold<int>(0, (s, o) => s + o.unblinded.value.toInt());
      final gross = inSum > outSum ? inSum : outSum;
      if (gross > winnerGross) {
        winnerGross = gross;
        winner = id;
      }
    }
    if (winner == null || winnerGross == 0) return null;
    return (assetId: winner, grossSat: winnerGross);
  }

  /// Pick the "headline" balance from a list of wallet-side balance
  /// entries. Preference order:
  ///   1. If only one entry, return it.
  ///   2. If `preferNonLbtc` is true and any non-L-BTC entry exists,
  ///      pick the non-L-BTC entry with the largest absolute value.
  ///   3. Otherwise pick the entry with the largest absolute value
  ///      across all entries.
  ///
  /// Rationale: a USDT/DePix transfer typically also includes the
  /// L-BTC fee leg, but the L-BTC delta is tiny compared to the asset
  /// movement. The user thinks of the transaction as "Sent 100 USDT",
  /// not "Sent 100 sats of L-BTC". Preferring non-L-BTC surfaces the
  /// economically meaningful number.
  lwk.Balance _pickMainBalance(
    List<lwk.Balance> balances, {
    required bool preferNonLbtc,
  }) {
    if (balances.length == 1) return balances.first;
    if (preferNonLbtc) {
      final nonLbtc = balances
          .where((b) => b.assetId != lbtcAssetId)
          .toList(growable: false);
      if (nonLbtc.isNotEmpty) {
        return nonLbtc.reduce(
          (a, b) => a.value.abs() > b.value.abs() ? a : b,
        );
      }
    }
    return balances.reduce(
      (a, b) => a.value.abs() > b.value.abs() ? a : b,
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
