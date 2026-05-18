import 'dart:async';

import '../../domain/entities/transaction.dart';
import '../../domain/events/transaction_event.dart';
import '../../domain/repositories/notified_tx_registry.dart';
import '../../domain/repositories/transaction_store.dart';
import '../../domain/services/transaction_notifier.dart';
import '../../features/sync/domain/sync_orchestrator.dart';
import '../../features/sync/domain/sync_state.dart';
import '../../features/wallet/data/models/transaction_status_event.dart';
import '../../shared/entities/asset.dart' as legacy_asset;
import '../../shared/logging/structured_logger.dart';

/// V2 transaction notifier. See the abstract interface for the full
/// state-machine contract; this impl implements it on top of:
///
///   - [SyncOrchestrator.transactions]: the merged tx-event stream from
///     all chain services. Each event is already persisted to
///     `transactionStore` by the orchestrator's single-writer pipeline
///     before it reaches us.
///   - [SyncOrchestrator.state]: used to detect first-sync settlement
///     so we can flip baseline → ready atomically.
///   - [NotifiedTxRegistry]: persisted dedup ledger keyed on
///     `(chain, tx_id)`. Survives cold restarts, wiped on
///     wallet-delete + import.
///   - [TransactionStore]: snapshotted on baseline init so the wallet's
///     pre-existing transactions are absorbed (marked-without-emitting).
///
/// The implementation is single-isolate (`dart:async` only) — no shared
/// state with other isolates, no concurrent calls. The minor races that
/// matter are between (a) the constructor finishing baseline init and
/// (b) live events arriving on the orchestrator stream. We buffer
/// live events for the duration of init and replay them at the end of
/// init through the same emission path the post-baseline events use.
class V2TransactionNotifier implements TransactionNotifier {
  V2TransactionNotifier({
    required SyncOrchestrator orchestrator,
    required NotifiedTxRegistry registry,
    required TransactionStore transactionStore,
    required StructuredLogger logger,
  })  : _orchestrator = orchestrator,
        _registry = registry,
        _transactionStore = transactionStore,
        _logger = logger {
    // Subscribe BEFORE awaiting baseline init so no event is lost in
    // the window between construction and the first await.
    _txSub = _orchestrator.transactions.listen(
      _onTransactionEvent,
      onError: (e, st) => _logger.warn('tx_notifier.stream_error',
          {'error': '$e'}, error: e, stackTrace: st),
    );
    // Sync state listener runs in parallel — used solely to clear the
    // baseline flag once the first refresh has settled successfully.
    _syncSub = _orchestrator.state.listen(_onSyncStateChange);
    // Kick off baseline init. The constructor returns immediately; the
    // tx stream is buffered until init completes.
    unawaited(_runBaselineInit());
  }

  final SyncOrchestrator _orchestrator;
  final NotifiedTxRegistry _registry;
  final TransactionStore _transactionStore;
  final StructuredLogger _logger;

  final _controller = StreamController<TransactionStatusEvent>.broadcast();
  StreamSubscription<TransactionEvent>? _txSub;
  StreamSubscription<SyncState>? _syncSub;
  bool _disposed = false;

  _BaselinePhase _baseline = _BaselinePhase.initializing;
  bool _homeReached = false;
  bool _foregrounded = true;

  /// Events that arrived while baseline was still initializing. Drained
  /// once init completes, then this stays empty for the notifier's
  /// lifetime.
  final List<TransactionEvent> _initBuffer = [];

  /// Pending notifications that passed dedup + baseline gates but
  /// were held because `homeReached` or `foregrounded` was false.
  /// Drained when both gates open. Volatile by design — process death
  /// loses these but the registry has already marked them, so cold
  /// restart will not re-show.
  final List<TransactionStatusEvent> _pendingEmissions = [];

  @override
  Stream<TransactionStatusEvent> get notifications => _controller.stream;

  @override
  void setHomeReached() {
    if (_homeReached) return;
    _homeReached = true;
    _logger.info('tx_notifier.home_reached', {});
    _maybeFlushPending();
  }

  @override
  void setForegrounded(bool foregrounded) {
    if (_foregrounded == foregrounded) return;
    _foregrounded = foregrounded;
    _logger.info('tx_notifier.foreground_changed',
        {'foregrounded': foregrounded});
    if (foregrounded) _maybeFlushPending();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _txSub?.cancel();
    _txSub = null;
    await _syncSub?.cancel();
    _syncSub = null;
    _initBuffer.clear();
    _pendingEmissions.clear();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  // ─────────────────────────────────────────── baseline init

  /// Snapshot the persisted transaction store and mark every existing
  /// tx as already-notified. This is the one-shot absorb-historical-txs
  /// pass that prevents N modals on a fresh install / cold restart of
  /// a wallet with existing tx history.
  ///
  /// Atomicity: events arriving on `_orchestrator.transactions` during
  /// this Future are buffered into `_initBuffer` by [_onTransactionEvent]
  /// because `_baseline == initializing`. Once we transition to ready,
  /// the buffer is drained through the normal emission path. Events for
  /// txs we just bulk-marked will hit the dedup check (markIfNew →
  /// false) and be silently dropped. Events for genuinely new txs that
  /// arrived after the snapshot will flow through normally.
  Future<void> _runBaselineInit() async {
    try {
      final baselineEither = await _registry.isBaselineComplete();
      final alreadyDone =
          baselineEither.getOrElse((_) => false);
      if (alreadyDone) {
        _baseline = _BaselinePhase.ready;
        _logger.info('tx_notifier.baseline_already_complete', {});
        await _drainInitBuffer();
        return;
      }

      _logger.info('tx_notifier.baseline_init_begin', {});
      final listResult = await _transactionStore.list();
      final txs = listResult.getOrElse((_) => const <Transaction>[]);
      if (txs.isNotEmpty) {
        final entries = txs.map(
          (t) => (chain: t.chain, txId: t.id),
        );
        final markResult = await _registry.bulkMark(entries);
        markResult.match(
          (f) => _logger.warn('tx_notifier.baseline_bulk_mark_failed',
              {'reason': f.message}),
          (_) => _logger.info('tx_notifier.baseline_marked',
              {'count': txs.length}),
        );
      }

      final completeResult = await _registry.setBaselineComplete();
      completeResult.match(
        (f) => _logger.warn('tx_notifier.baseline_flag_failed',
            {'reason': f.message}),
        (_) => _logger.info('tx_notifier.baseline_complete', {}),
      );
      _baseline = _BaselinePhase.ready;
      await _drainInitBuffer();
    } catch (e, st) {
      _logger.error('tx_notifier.baseline_init_threw',
          {'error': '$e'}, error: e, stackTrace: st);
      // Fail open: advance to ready so live events flow. The registry's
      // markIfNew is still our line of defence against duplicates.
      _baseline = _BaselinePhase.ready;
      await _drainInitBuffer();
    }
  }

  Future<void> _drainInitBuffer() async {
    if (_initBuffer.isEmpty) return;
    final buffered = List<TransactionEvent>.from(_initBuffer);
    _initBuffer.clear();
    for (final e in buffered) {
      await _processEvent(e);
    }
  }

  /// Called whenever the sync orchestrator's state stream emits. The
  /// only thing we care about: the first successful sync after a fresh
  /// install/import. If baseline somehow didn't complete during init
  /// (e.g. the constructor's `list()` ran before the orchestrator had
  /// finished its first writes), the first `lastSuccessAt != null`
  /// emission gives us a second chance to mark it.
  void _onSyncStateChange(SyncState state) {
    if (_baseline == _BaselinePhase.ready) return;
    if (state.lastSuccessAt == null) return;
    // The first sync settled but we're still in `initializing` — likely
    // means the init started before the orchestrator could write any
    // txs to the store. The buffered events will carry the new txs, so
    // we just flip the flag and let `_drainInitBuffer` handle them.
    _logger.info('tx_notifier.baseline_advanced_via_sync_state', {});
    unawaited(_registry.setBaselineComplete());
    _baseline = _BaselinePhase.ready;
    unawaited(_drainInitBuffer());
  }

  // ─────────────────────────────────────────── live event path

  void _onTransactionEvent(TransactionEvent event) {
    if (_disposed) return;
    if (_baseline == _BaselinePhase.initializing) {
      _initBuffer.add(event);
      return;
    }
    unawaited(_processEvent(event));
  }

  Future<void> _processEvent(TransactionEvent event) async {
    final tx = event.transaction;

    // Only notify on incoming receives that have just reached "confirmed".
    // We treat both `created` events that arrive already-confirmed
    // (re-imports, late tx push) and `statusChanged` from pending→confirmed
    // the same way. Outgoing sends, self-transfers / consolidations,
    // swaps (user-initiated), and unconfirmed events are ignored.
    final isUserFacingReceive =
        tx.direction == TransactionDirection.incoming ||
            tx.direction == TransactionDirection.internal;
    if (!isUserFacingReceive) return;
    if (tx.status != TransactionStatus.confirmed) return;

    // Persisted dedup: atomic INSERT OR IGNORE. If the row already
    // existed, this tx has already been processed (or absorbed during
    // baseline) — silently drop.
    final markResult = await _registry.markIfNew(
      chain: tx.chain,
      txId: tx.id,
    );
    final isFreshlyMarked = markResult.getOrElse((_) => false);
    if (!isFreshlyMarked) return;

    final assetId = tx.assetId ?? _defaultAssetIdForChain(tx);
    if (assetId == null) {
      _logger.debug('tx_notifier.no_asset_id_drop',
          {'tx_id': tx.id, 'chain': tx.chain.name});
      return;
    }

    final statusEvent = TransactionStatusEvent(
      transactionId: tx.id,
      assetId: assetId,
      assetTicker: _tickerFor(assetId),
      amount: BigInt.from(tx.amountSat),
      confirmedAt: event.observedAt,
    );

    if (_canEmitNow()) {
      _emit(statusEvent);
    } else {
      _logger.debug('tx_notifier.gated_pending',
          {'tx_id': tx.id, 'home': _homeReached, 'fg': _foregrounded});
      _pendingEmissions.add(statusEvent);
    }
  }

  bool _canEmitNow() => _homeReached && _foregrounded;

  void _maybeFlushPending() {
    if (!_canEmitNow()) return;
    if (_pendingEmissions.isEmpty) return;
    final drained = List<TransactionStatusEvent>.from(_pendingEmissions);
    _pendingEmissions.clear();
    _logger.info('tx_notifier.flush_pending', {'count': drained.length});
    for (final e in drained) {
      _emit(e);
    }
  }

  void _emit(TransactionStatusEvent event) {
    if (_disposed || _controller.isClosed) return;
    _controller.add(event);
  }

  // ─────────────────────────────────────────── helpers

  /// Maps a chain to a fallback asset id when the tx record does not
  /// carry one (Bitcoin / Lightning chains do not set `assetId`).
  String? _defaultAssetIdForChain(Transaction tx) {
    final asset = switch (tx.chain.name) {
      'bitcoin' => legacy_asset.Asset.btc,
      'lightning' => legacy_asset.Asset.btc,
      _ => null,
    };
    return asset?.id;
  }

  /// Best-effort ticker lookup using the legacy `Asset` enum. Unknown
  /// asset ids fall back to a short prefix of the id so the UI has
  /// something to display.
  String _tickerFor(String assetId) {
    try {
      return legacy_asset.Asset.fromId(assetId).ticker;
    } catch (_) {
      return assetId.length > 6 ? assetId.substring(0, 6) : assetId;
    }
  }
}

enum _BaselinePhase {
  initializing,
  ready,
}
