import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../domain/entities/chain.dart';
import '../../../domain/entities/wallet_credentials.dart';
import '../../../domain/events/sync_outcome.dart';
import '../../../domain/events/transaction_event.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/repositories/transaction_store.dart';
import '../../../domain/services/bitcoin_wallet_service.dart';
import '../../../domain/services/lightning_wallet_service.dart';
import '../../../domain/services/liquid_wallet_service.dart';
import '../../../domain/services/service_state.dart';
import '../../../domain/services/wallet_service.dart';
import '../../../shared/clock/clock.dart';
import '../../../shared/concurrency/mutex.dart';
import '../../../shared/concurrency/single_flight.dart';
import '../../../shared/diagnostics/boot_tracer.dart';
import '../../../shared/logging/structured_logger.dart';
import '../../../shared/streams/replay_value_stream.dart';
import '../domain/sync_config.dart';
import '../domain/sync_orchestrator.dart';
import '../domain/sync_state.dart';
import '../domain/sync_strategy.dart';

class SyncOrchestratorImpl implements SyncOrchestrator {
  SyncOrchestratorImpl({
    required this.liquid,
    required this.bitcoin,
    required this.lightning,
    required this.transactionStore,
    required this.config,
    required this.logger,
    required this.clock,
  });

  final LiquidWalletService liquid;
  final BitcoinWalletService bitcoin;
  final LightningWalletService lightning;
  final TransactionStore transactionStore;
  final SyncConfig config;
  final StructuredLogger logger;
  final Clock clock;

  late final List<WalletService> _services = [liquid, bitcoin, lightning];

  final Mutex _mutex = Mutex();
  final SingleFlight<String, Either<SyncFailure, SyncOutcome>> _flight =
      SingleFlight();

  final ReplayValueStream<SyncState> _state =
      ReplayValueStream<SyncState>.seeded(SyncState.idle());
  final StreamController<TransactionEvent> _txController =
      StreamController<TransactionEvent>.broadcast();
  final List<StreamSubscription> _subs = [];
  Timer? _ticker;
  bool _started = false;

  // Event coalescer. A single sync cycle on a busy wallet emits dozens of
  // TransactionEvents over a short window (LWK fires one per tx changed,
  // Breez fires one per payment touched). Persisting them one-by-one means
  // one sqlite prepare/exec per event + one watch-emit per event +
  // one downstream compute() per event — visible UI freeze on big wallets.
  // We buffer events for `_flushInterval` and persist with `upsertAll`,
  // which collapses the storm into one watch emit per burst.
  final List<TransactionEvent> _persistBuffer = [];
  Timer? _persistFlushTimer;
  static const Duration _flushInterval = Duration(milliseconds: 50);

  @override
  Stream<SyncState> get state => _state.stream;
  @override
  SyncState get currentState => _state.value;
  @override
  Stream<TransactionEvent> get transactions => _txController.stream;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    logger.info('sync.start', {});

    // Subscribe to per-chain transaction streams; persist + republish.
    for (final s in _services) {
      _subs.add(s.transactions.listen(
        _onTransactionEvent,
        onError: (Object e, StackTrace st) =>
            logger.error('sync.tx.stream', {'chain': s.chain.name}, error: e, stackTrace: st),
      ));
    }

    if (config.startupSyncOnBoot) {
      await refresh(strategy: SyncStrategy.light);
    }

    _ticker = Timer.periodic(config.tick, (_) {
      _flight
          .run('periodic-light', () => refresh(strategy: SyncStrategy.light))
          .catchError((Object e, StackTrace st) {
            logger.error('sync.periodic.error', {}, error: e, stackTrace: st);
            return Left<SyncFailure, SyncOutcome>(SyncFailure(
              'periodic refresh failed: $e',
              chain: ChainId.aggregate,
              cause: e,
              stackTrace: st,
            ));
          });
    });
  }

  @override
  Future<Either<SyncFailure, SyncOutcome>> refresh({
    SyncStrategy strategy = SyncStrategy.light,
  }) {
    final key = 'refresh:${strategy.name}';
    return _flight.run(key, () => _mutex.protect(() => _runRefresh(strategy)));
  }

  @override
  Future<Either<SyncFailure, SyncOutcome>> reconnect({
    required WalletCredentials credentials,
  }) {
    // Same `_flight` keyspace as `refresh()` so a manual reconnect issued
    // while the periodic ticker's refresh is in flight does not pile up —
    // the reconnect waits for the in-flight refresh, then runs once and
    // emits a single completion. The mutex serialises with `_runRefresh`
    // so we never reconnect a service mid-sync (which would invalidate
    // the SDK handle the sync loop is iterating).
    return _flight.run(
      'reconnect',
      () => _mutex.protect(() => _runReconnect(credentials)),
    );
  }

  Future<Either<SyncFailure, SyncOutcome>> _runReconnect(
      WalletCredentials credentials) async {
    logger.info('sync.reconnect.begin', {});
    final t0 = clock.now();

    // Walk every service. For non-operational services, disconnect (idempotent)
    // and reconnect with the supplied credentials. Skip services that are
    // already connected — reconnecting a healthy service would interrupt an
    // in-progress flow for no reason.
    int recoveredCount = 0;
    int failedCount = 0;
    ServiceFailure? lastReconnectFailure;
    for (final s in _services) {
      if (s.currentState.isOperational) {
        logger.debug('sync.reconnect.skip',
            {'chain': s.chain.name, 'reason': 'already operational'});
        continue;
      }
      logger.info('sync.reconnect.attempt', {'chain': s.chain.name});
      try {
        // Disconnect is idempotent — see each service's impl. We call it
        // unconditionally to release any half-acquired FFI handle / workdir
        // lock from the previous failed connect, then proceed to connect.
        await s.disconnect();
        final r = await s.connect(credentials);
        r.match(
          (f) {
            failedCount++;
            lastReconnectFailure = f;
            logger.warn('sync.reconnect.failed',
                {'chain': s.chain.name, 'reason': f.message});
          },
          (_) {
            recoveredCount++;
            logger.info('sync.reconnect.ok', {'chain': s.chain.name});
          },
        );
      } catch (e, st) {
        failedCount++;
        lastReconnectFailure = ServiceFailure(
          'reconnect threw: $e',
          chain: s.chain,
          cause: e,
          stackTrace: st,
        );
        logger.error('sync.reconnect.threw',
            {'chain': s.chain.name, 'error': '$e'},
            error: e, stackTrace: st);
      }
    }

    // After the reconnect pass, kick a light refresh through the same
    // mechanism `refresh()` uses. We're already inside `_mutex.protect`,
    // so we call `_runRefresh` directly (re-entering the mutex would
    // deadlock).
    final refreshOutcome = await _runRefresh(SyncStrategy.light);
    final duration = clock.now().difference(t0);
    logger.info('sync.reconnect.end', {
      'recovered': recoveredCount,
      'failed': failedCount,
      'duration_ms': duration.inMilliseconds,
    });

    // Soft-degrade: if at least one service is operational after reconnect,
    // we report success even if some others still fail. This mirrors the
    // boot orchestrator's `allFailed` check.
    final operationalAfter =
        _services.where((s) => s.currentState.isOperational).length;
    if (operationalAfter == 0 && lastReconnectFailure != null) {
      return Left(SyncFailure(
        'reconnect: no service operational: ${lastReconnectFailure!.message}',
        chain: lastReconnectFailure!.chain,
        cause: lastReconnectFailure,
      ));
    }
    return refreshOutcome;
  }

  Future<Either<SyncFailure, SyncOutcome>> _runRefresh(
      SyncStrategy strategy) async {
    final t0 = clock.now();
    final perChain = <ChainId, ServiceLifecycle>{};
    for (final s in _services) {
      perChain[s.chain] = s.currentState.lifecycle;
    }
    _emit(currentState.copyWith(
      phase: SyncPhase.running,
      perChain: perChain,
      clearError: true,
    ));

    final outcomes = <ChainId, Either<ServiceFailure, SyncOutcome>>{};
    int totalFetched = 0;
    int totalChanged = 0;

    // Parallel by design (2026-05-24): the previous sequential walk
    // (liquid → bitcoin → lightning) meant that a slow or timing-out
    // LWK sync starved Bitcoin and Breez behind a 60 s wait, with the
    // user-visible effect that Liquid asset swaps (which come from
    // Breez) did not appear on the home list until the LWK timeout
    // fired. The three SDKs live in their own isolates / network
    // contexts (LWK Rust isolate, BDK Rust isolate, Breez gRPC
    // session); none of them shares mutable state and each carries
    // its own `_syncMutex`, so running them concurrently is safe and
    // strictly faster.
    final inFlight = <ChainId, Future<Either<ServiceFailure, SyncOutcome>>>{};
    for (final s in _services) {
      if (!s.currentState.isOperational) {
        outcomes[s.chain] = Left(ServiceFailure('not operational',
            chain: s.chain));
        continue;
      }
      final timeout = config.timeoutFor(s.chain);
      logger.debug('sync.chain.begin',
          {'chain': s.chain.name, 'timeout_ms': timeout.inMilliseconds});

      inFlight[s.chain] = () async {
        try {
          return await s.sync(timeout: timeout).timeout(
                timeout + const Duration(seconds: 5),
                onTimeout: () => Left(ServiceFailure('sync hard timeout',
                    chain: s.chain)),
              );
        } catch (e, st) {
          return Left<ServiceFailure, SyncOutcome>(ServiceFailure(
              'sync threw: $e',
              chain: s.chain, cause: e, stackTrace: st));
        }
      }();
    }

    // Collect results as each chain finishes so we can log per-chain
    // completion as it happens (preserves the old observability where
    // the trace shows each `sync.chain.ok` line at the moment that
    // chain returned).
    //
    // Progressive `lastSuccessAt` (2026-05-24): the first chain to
    // return successfully bumps `lastSuccessAt` immediately, even
    // while sibling chains keep syncing. Consumers gating on "did at
    // least one chain return?" (the import-loading gate, progressive
    // hydration) can advance the moment Bitcoin or Lightning land,
    // without sitting behind a possible 60 s LWK timeout. The terminal
    // `cooling` emit at the end still runs and carries the final
    // aggregate state.
    await Future.wait(inFlight.entries.map((entry) async {
      final r = await entry.value;
      outcomes[entry.key] = r;
      // Settle ordering (2026-05-24): we must guarantee that by the
      // time a chain lands in `firstSyncedChains`, its data is already
      // in the transaction store — otherwise the import-loading gate
      // fires, the home mounts, subscribes to the store, and renders
      // an empty list for this chain because the writes are still in
      // flight. The user-visible symptom is "home opened with only
      // BDK" until Lightning/Liquid pop in a few seconds later.
      //
      // Two-step settle:
      //   (a) Yield the event loop once. The chain's `_diffAndEmit`
      //       added TransactionEvents to its own `_txController`
      //       synchronously during sync, but the orchestrator's
      //       listener (`_onTransactionEvent`) is invoked as a
      //       microtask. Yielding lets those microtasks drain so the
      //       events land in `_persistBuffer`.
      //   (b) Force-flush the buffer and await the `upsertAll`. After
      //       this, the chain's events are in the sqlite store and
      //       any new `watch()` subscriber will see them in its
      //       initial yield.
      await Future<void>.delayed(Duration.zero);
      await _flushPersistBufferNow();
      // Settled semantics (2026-05-24 redesign): ONLY successful chain
      // syncs land in `firstSyncedChains`. The previous version added
      // failed chains too, which meant a Breez/LWK timeout flipped
      // `lightningSettled` to true in the import-loading gate — the
      // home opened with empty Breez data after a long wait.
      //
      // With this change, the gate's `lightningSettled` only fires
      // when Breez actually returned payments. If Breez fails, the
      // gate falls back to `allSettled` (phase == cooling, which only
      // emits once `Future.wait` completes — i.e., after every
      // operational chain's per-chain timeout fires). That bounds the
      // worst-case wait at the LONGEST per-chain timeout, while
      // letting the gate release immediately on the happy path where
      // Breez succeeds early.
      r.match(
        (f) {
          logger.warn('sync.chain.failed',
              {'chain': entry.key.name, 'reason': f.message});
          // No state emit on failure — keep `firstSyncedChains`
          // unchanged. The chain's final outcome is still captured
          // in `outcomes[entry.key]` for the aggregate emit below.
        },
        (o) {
          totalFetched += o.fetched;
          totalChanged += o.changed;
          logger.info('sync.chain.ok', {
            'chain': entry.key.name,
            'duration_ms': o.duration.inMilliseconds,
            'fetched': o.fetched,
            'changed': o.changed,
          });
          // Success path: stamp the chain as first-synced + bump
          // lifecycle + lastSuccessAt so progressive UX (per-chain
          // "synced X" message) can react immediately.
          final firstSynced = <ChainId>{
            ...currentState.firstSyncedChains,
            entry.key,
          };
          final updatedPerChain = <ChainId, ServiceLifecycle>{
            ...currentState.perChain,
            entry.key: ServiceLifecycle.connected,
          };
          _emit(currentState.copyWith(
            perChain: updatedPerChain,
            lastSuccessAt: clock.now(),
            firstSyncedChains: firstSynced,
            clearError: true,
          ));
        },
      );
    }));

    // Lightning rescan only on full strategy.
    if (strategy == SyncStrategy.full) {
      final lr = await lightning.rescan(window: config.fullSyncRescanWindow);
      lr.match(
        (f) => logger.warn('sync.lightning.rescan.failed', {'reason': f.message}),
        (_) => logger.info('sync.lightning.rescan.ok', {}),
      );
    }

    final duration = clock.now().difference(t0);
    final aggregate = SyncOutcome(
      chain: ChainId.aggregate,
      fetched: totalFetched,
      changed: totalChanged,
      duration: duration,
    );

    final operationalServices =
        _services.where((s) => s.currentState.isOperational).toList();
    final operationalFailed = operationalServices.where((s) =>
        outcomes[s.chain]?.isLeft() ?? false);

    final allFailed = operationalServices.isNotEmpty &&
        operationalFailed.length == operationalServices.length;

    final newPerChain = <ChainId, ServiceLifecycle>{
      for (final s in _services) s.chain: s.currentState.lifecycle,
    };

    if (allFailed) {
      final firstFail = outcomes.values.firstWhere((r) => r.isLeft());
      final failure = firstFail.swap().getOrElse(
            (_) => ServiceFailure('unknown', chain: ChainId.aggregate),
          );
      final sf = SyncFailure(
        'all operational services failed: ${failure.message}',
        chain: failure.chain,
        cause: failure,
      );
      _emit(currentState.copyWith(
        phase: SyncPhase.cooling,
        perChain: newPerChain,
        lastError: sf,
        lastDuration: duration,
      ));
      return Left(sf);
    }

    _emit(currentState.copyWith(
      phase: SyncPhase.cooling,
      perChain: newPerChain,
      lastSuccessAt: clock.now(),
      lastDuration: duration,
      clearError: true,
    ));
    return Right(aggregate);
  }

  void _onTransactionEvent(TransactionEvent event) {
    // Buffer + flush. The single-event upsert path used to spawn one
    // sqlite write and one watch-emit per event; on a hot sync that
    // produced dozens of UI-thread microtasks back to back. Batching
    // lets one `upsertAll` write N rows under a single prepared
    // statement and emit a single coalesced watch tick.
    _persistBuffer.add(event);
    _persistFlushTimer ??= Timer(_flushInterval, _flushPersistBuffer);
  }

  void _flushPersistBuffer() {
    // Fire-and-forget wrapper around `_flushPersistBufferNow` for the
    // Timer callback — the Timer can't await the returned Future, and
    // we don't need to: stale flushes are harmless (subsequent
    // explicit flushes from `_runRefresh` will pick up anything left
    // in the buffer).
    // ignore: unawaited_futures
    _flushPersistBufferNow();
  }

  /// Awaitable flush: drains the persist buffer and waits for the
  /// resulting `upsertAll` to complete. Used by `_runRefresh` after
  /// each chain's sync returns, so consumers seeing the chain land in
  /// `firstSyncedChains` can assume that chain's data is committed.
  Future<void> _flushPersistBufferNow() async {
    _persistFlushTimer?.cancel();
    _persistFlushTimer = null;
    if (_persistBuffer.isEmpty) return;
    final batch = List<TransactionEvent>.unmodifiable(_persistBuffer);
    _persistBuffer.clear();
    final tEnter = clock.now();
    final txs = batch.map((e) => e.transaction).toList(growable: false);
    final r = await transactionStore.upsertAll(txs);
    final persistMs = clock.now().difference(tEnter).inMilliseconds;
    BootTracer.mark('sync.tx.persist.batch', {
      'n': batch.length,
      'dur_ms': persistMs,
    });
    r.match(
      (f) => logger.warn('sync.tx.persist.batch.failed',
          {'n': batch.length, 'reason': f.message}),
      (_) {
        if (_txController.isClosed) return;
        for (final event in batch) {
          _txController.add(event);
        }
      },
    );
  }

  void _emit(SyncState s) {
    if (_state.isClosed) return;
    _state.add(s);
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    _ticker?.cancel();
    _ticker = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    // Flush any buffered events synchronously — losing the last 50ms
    // worth of TransactionEvents on shutdown would manifest as a stale
    // tx list after the next launch.
    _persistFlushTimer?.cancel();
    _persistFlushTimer = null;
    _flushPersistBuffer();

    // Drain any in-flight `_runRefresh` / `_runReconnect`. Without this,
    // a periodic-tick refresh that fired moments before delete is still
    // sitting inside `await s.sync(...)` for liquid — holding the chain
    // service's `_syncMutex` and (during reconnect) its `_connectMutex`.
    // Boot.shutdown's `liquid.disconnect()` would then queue forever.
    // The hard timeout caps the wait — past it, the per-service
    // `_shuttingDown` flag short-circuits the connect path and
    // boot.shutdown's own per-disconnect timeout finishes the job.
    try {
      await _mutex
          .protect(() async {})
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      logger.warn('sync.stop.drain_timeout',
          {'reason': 'in-flight refresh/reconnect did not finish in 5s'});
    }

    // CRITICAL (2026-05-24): wipe per-wallet sync state on stop. The
    // delete+reimport flow calls `stop()` between wallets, but the
    // orchestrator is a singleton (lives in the Riverpod tree and is
    // not invalidated by the import button). Without this reset, the
    // next wallet inherits `firstSyncedChains = {liquid, bitcoin,
    // lightning}` and `lastSuccessAt = <old time>` from the previous
    // wallet — the `WalletImportLoadingScreen` gate then sees
    // `lightningSettled == true` immediately on the new boot's first
    // state emit and routes the user to /home BEFORE the new wallet
    // has fetched anything. Result: home opens "empty" then suddenly
    // populates with the new wallet's data many seconds later
    // (sometimes still rendering stale balance from the chain
    // services' in-memory caches in the interim).
    //
    // Reset everything except the `phase=stopped` marker; the next
    // `start()` will populate `perChain` from the freshly-reconnected
    // services and rebuild `firstSyncedChains` from the new wallet's
    // sync results.
    _emit(const SyncState(
      phase: SyncPhase.stopped,
      perChain: <ChainId, ServiceLifecycle>{},
    ));
    logger.info('sync.stop', {});
  }

  @override
  Future<void> dispose() async {
    await stop();
    if (!_txController.isClosed) await _txController.close();
    await _state.close();
  }
}
