import 'dart:async';
import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/analytics/product_flows.dart';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';
import 'package:mooze_mobile/shared/concurrency/liquid_spend_coordinator.dart';

import '../../domain/repositories/swap_repository.dart';
import '../mappers/core_swap_mapper.dart';
import '../models.dart';
import '../services/core_sideswap_session.dart';

/// [SwapRepository] backed by the mooze-core SideSwap client.
///
/// The repository listens to `sideswapEvents` while it lives and forwards
/// the quotes to [quoteStream]. After a `disconnected` event, the core
/// reconnects and this class starts the last quote again, as the Dart
/// `SideswapService` did. [dispose] stops the quote and the event stream,
/// but keeps the connection open, because the peg tracker shares it.
class CoreSwapRepository implements SwapRepository {
  CoreSwapRepository({required CoreSideswapSession session, void Function(AnalyticsEvent)? track})
      : _session = session, _track = track ?? ((_) {});

  final void Function(AnalyticsEvent) _track;

  final CoreSideswapSession _session;
  final _quotes = StreamController<QuoteResponse>.broadcast();
  List<SideswapMarket> _cachedMarkets = [];

  StreamSubscription<SideSwapEventDto>? _events;
  Future<void>? _eventsOpening;
  ({String send, String receive, BigInt amount})? _activeQuote;
  bool _disposed = false;

  @override
  TaskEither<String, List<SideswapAsset>> getAssets() => _guard((core) async {
        final list = await core.sideswapAssets();
        return list.map(sideswapAssetFromDto).toList(growable: false);
      });

  @override
  TaskEither<String, List<SideswapMarket>> getMarkets() => _guard((core) async {
        final list = await core.sideswapMarkets();
        _cachedMarkets = list.map(sideswapMarketFromDto).toList();
        return _cachedMarkets;
      });

  @override
  ({
    String baseAsset,
    String quoteAsset,
    SwapDirection direction,
    String assetType,
  })?
  normalizeSwapParams({
    required String sendAsset,
    required String receiveAsset,
  }) {
    final direct = _cachedMarkets.any(
      (m) => m.baseAssetId == sendAsset && m.quoteAssetId == receiveAsset,
    );
    if (direct) {
      return (
        baseAsset: sendAsset,
        quoteAsset: receiveAsset,
        direction: SwapDirection.sell,
        assetType: 'Base',
      );
    }
    final inverse = _cachedMarkets.any(
      (m) => m.baseAssetId == receiveAsset && m.quoteAssetId == sendAsset,
    );
    if (inverse) {
      return (
        baseAsset: receiveAsset,
        quoteAsset: sendAsset,
        direction: SwapDirection.sell,
        assetType: 'Quote',
      );
    }
    return null;
  }

  @override
  Future<Either<String, Stream<QuoteResponse>>> startQuote({
    required String sendAsset,
    required String receiveAsset,
    required BigInt amount,
  }) async {
    if (_disposed) return left('Swap encerrado');
    _activeQuote = (send: sendAsset, receive: receiveAsset, amount: amount);
    final result = await _start(_activeQuote!).run();
    return result.map((_) => _quotes.stream);
  }

  @override
  Stream<QuoteResponse> get quoteStream => _quotes.stream;

  @override
  void stopQuote() {
    _activeQuote = null;
    unawaited(
      _session.core
          .then((core) => core.sideswapStopQuote())
          .catchError((Object _) {}),
    );
  }

  @override
  Future<void> forceReconnect() async {
    if (_disposed) return;
    final core = await _session.core;
    await _closeEvents();
    await core.sideswapDisconnect();
    await _session.connected();
    await _ensureEvents();
  }

  @override
  TaskEither<String, String> executeSwap(int quoteId) {
    return TaskEither(() => trackOperation(
      track: _track,
      started: const AnalyticsEvent('swap_started', {'swap_type': 'liquid'}),
      failed: const AnalyticsEvent('swap_failed', {'swap_type': 'liquid'}),
      outcome: (value) => AnalyticsEvent(value.isRight() ? 'swap_submission_succeeded' : 'swap_failed', const {'swap_type': 'liquid'}),
      run: () => _executeSwap(quoteId).run(),
    ));
  }

  TaskEither<String, String> _executeSwap(int quoteId) {
    return TaskEither(() async {
      try {
        return await LiquidSpendCoordinator.instance.protect(
          'sideswap:assetSwap',
          () => _guard(
            (core) => core.sideswapExecuteSwap(quoteId: BigInt.from(quoteId)),
          ).run(),
        );
      } on LiquidSpendLockTimeout catch (e) {
        return left(e.toString());
      }
    });
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _activeQuote = null;
    unawaited(_closeEvents());
    unawaited(
      _session.core.then((core) async {
        await core.sideswapStopQuote();
        await core.sideswapCloseEvents();
      }).catchError((Object _) {}),
    );
    _quotes.close();
  }

  /// Opens the event stream once. Quotes need it.
  Future<void> _ensureEvents() {
    if (_disposed || _events != null) return Future.value();
    return _eventsOpening ??= _openEvents().whenComplete(
      () => _eventsOpening = null,
    );
  }

  Future<void> _openEvents() async {
    final core = await _session.connected();
    if (_disposed || _events != null) return;
    _events = core.sideswapEvents().listen(
      _onEvent,
      onError: (Object e) {
        if (kDebugMode) debugPrint('[CoreSwapRepository] event error: $e');
      },
      onDone: () => _events = null,
    );
  }

  Future<void> _closeEvents() async {
    final events = _events;
    _events = null;
    await events?.cancel();
  }

  void _onEvent(SideSwapEventDto event) {
    if (_disposed) return;
    switch (event.kind) {
      case SideSwapEventKind.quote:
        final quote = event.quote;
        if (quote != null && !_quotes.isClosed) {
          _quotes.add(quoteResponseFromDto(quote));
        }
      case SideSwapEventKind.disconnected:
        _restartActiveQuote();
      case SideSwapEventKind.closed:
        // The core driver stopped. The next quote opens a new stream.
        _events = null;
      case SideSwapEventKind.pegInWalletBalance:
      case SideSwapEventKind.pegOutWalletBalance:
        break;
    }
  }

  /// The core reconnects after a drop, but the server forgets the quote
  /// subscription. Starts the last quote again.
  void _restartActiveQuote() {
    final active = _activeQuote;
    if (active == null) return;
    unawaited(
      _start(active).run().then((result) {
        result.match(
          (err) {
            if (kDebugMode) {
              debugPrint('[CoreSwapRepository] quote restart failed: $err');
            }
          },
          (_) {},
        );
      }),
    );
  }

  TaskEither<String, Unit> _start(
    ({String send, String receive, BigInt amount}) intent,
  ) =>
      _guard((core) async {
        await _ensureEvents();
        final started = await core.sideswapStartQuote(
          sendAssetId: intent.send,
          receiveAssetId: intent.receive,
          amount: intent.amount,
        );
        if (!started.started) {
          throw StateError('Outra cotação está em andamento. Tente novamente.');
        }
        return unit;
      });

  TaskEither<String, T> _guard<T>(Future<T> Function(MoozeCore core) body) =>
      TaskEither.tryCatch(
        () async => body(await _session.connected()),
        (e, _) => e is StateError ? e.message : coreErrorMessage(e),
      );
}
