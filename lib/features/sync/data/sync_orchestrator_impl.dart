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

  // Persistence batching. First sync of a fresh wallet can produce 200+
  // events per chain, and `transactionStore.upsert` here calls a sync FFI
  // sqlite3 prepare/execute on the UI isolate. Buffering events and
  // flushing in a single SQL transaction (via `upsertAll`) collapses
  // ~430 fsyncs into a handful and keeps the home screen jank-free.
  // We flush on size or timer, whichever fires first.
  static const int _flushBatchSize = 64;
  static const Duration _flushInterval = Duration(milliseconds: 100);
  final List<TransactionEvent> _pendingEvents = [];
  Timer? _flushTimer;

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

    // Sequential by design: avoids LWK isolate + BDK CPU + Breez network
    // colliding on the same device. Order is liquid → bitcoin → lightning.
    for (final s in _services) {
      if (!s.currentState.isOperational) {
        outcomes[s.chain] = Left(ServiceFailure('not operational',
            chain: s.chain));
        continue;
      }
      final timeout = config.timeoutFor(s.chain);
      logger.debug('sync.chain.begin',
          {'chain': s.chain.name, 'timeout_ms': timeout.inMilliseconds});

      Either<ServiceFailure, SyncOutcome> r;
      try {
        r = await s.sync(timeout: timeout).timeout(
              timeout + const Duration(seconds: 5),
              onTimeout: () => Left(ServiceFailure('sync hard timeout',
                  chain: s.chain)),
            );
      } catch (e, st) {
        r = Left(ServiceFailure('sync threw: $e',
            chain: s.chain, cause: e, stackTrace: st));
      }
      outcomes[s.chain] = r;
      r.match(
        (f) => logger.warn('sync.chain.failed',
            {'chain': s.chain.name, 'reason': f.message}),
        (o) {
          totalFetched += o.fetched;
          totalChanged += o.changed;
          logger.info('sync.chain.ok', {
            'chain': s.chain.name,
            'duration_ms': o.duration.inMilliseconds,
            'fetched': o.fetched,
            'changed': o.changed,
          });
        },
      );
    }

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
    // Single writer, batched. Append to the pending buffer and either
    // flush immediately when the batch is full, or arm the flush timer so
    // bursts that don't reach `_flushBatchSize` still drain inside
    // `_flushInterval`. Republish to `_txController` only happens after a
    // successful flush so the persist-before-republish invariant is kept.
    if (_txController.isClosed) return;
    _pendingEvents.add(event);
    if (_pendingEvents.length >= _flushBatchSize) {
      _flushTimer?.cancel();
      _flushTimer = null;
      unawaited(_flushPending());
      return;
    }
    _flushTimer ??= Timer(_flushInterval, () {
      _flushTimer = null;
      unawaited(_flushPending());
    });
  }

  Future<void> _flushPending() async {
    if (_pendingEvents.isEmpty) return;
    // Drain into a local list so concurrent `_onTransactionEvent` calls
    // (legitimate during a sync) keep buffering into the next batch.
    final batch = List<TransactionEvent>.from(_pendingEvents);
    _pendingEvents.clear();

    final txs = batch.map((e) => e.transaction).toList(growable: false);
    final r = await transactionStore.upsertAll(txs);
    r.match(
      (f) {
        logger.warn('sync.tx.persist.batch.failed',
            {'count': batch.length, 'reason': f.message});
        // Fail-soft: do not republish events whose persistence failed.
        // Next sync round will re-emit them.
      },
      (_) {
        logger.debug('sync.tx.persist.batch', {'count': batch.length});
        if (_txController.isClosed) return;
        for (final ev in batch) {
          _txController.add(ev);
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
    // Drain any pending transaction events so the last batch is persisted
    // before we stop. Without this, a stop() called right after a sync
    // would leave the in-memory buffer unflushed and the UI would see a
    // stale tx list until the next sync cycle.
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingEvents.isNotEmpty) {
      await _flushPending();
    }
    _emit(currentState.copyWith(phase: SyncPhase.stopped));
    logger.info('sync.stop', {});
  }

  @override
  Future<void> dispose() async {
    await stop();
    if (!_txController.isClosed) await _txController.close();
    await _state.close();
  }
}
