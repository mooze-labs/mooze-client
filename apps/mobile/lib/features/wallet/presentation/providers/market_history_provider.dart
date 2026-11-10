import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_period.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/cached_price_history.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/services/price_history_cache_service.dart';

export 'package:mooze_mobile/shared/prices/models/cached_price_history.dart';

/// Price histories of the market sheet, served from a cache first and
/// refreshed from the network in the background.
///
/// The network stays the source of truth: the cache only lets a chart show
/// at once. Rules:
/// - Memory holds every history of the session. Shared preferences keep
///   them across restarts, until they are [maxAge] old.
/// - One request per history at a time. A second caller joins the request
///   in flight.
/// - A response never replaces a history from a later request.
/// - An unchanged response keeps the cached list, so a chart does not
///   redraw.
/// - A failed request keeps the cached history.
class MarketHistoryRepository {
  MarketHistoryRepository({
    required PriceHistoryFetcher fetch,
    PriceHistoryCacheService? store,
    DateTime Function()? now,
  }) : _fetch = fetch,
       _store = store ?? PriceHistoryCacheService(),
       _now = now ?? DateTime.now;

  /// Age after which a stored history is dropped.
  static const Duration maxAge = Duration(days: 7);

  /// Smallest age of a history that a reopened chart refreshes. It saves
  /// a request when the user opens the same chart twice in a row.
  static const Duration reopenGap = Duration(seconds: 30);

  final PriceHistoryFetcher _fetch;
  final PriceHistoryCacheService _store;
  final DateTime Function() _now;

  final Map<String, CachedPriceHistory> _memory = {};
  final Map<String, Future<Either<String, CachedPriceHistory>>> _inFlight = {};
  final StreamController<String> _updates = StreamController.broadcast();
  Future<void>? _restored;

  /// Returns the cache key of a history.
  static String keyOf(Asset asset, Currency currency, MarketPeriod period) =>
      '${asset.id}_${currency.name}_${period.name}';

  /// Emits the key of each history that changed.
  Stream<String> get updates => _updates.stream;

  /// Loads the stored histories into memory, once. A history already in
  /// memory is newer, so it stays.
  Future<void> restore() => _restored ??= _store
      .readAll(now: _now(), maxAge: maxAge)
      .match((_) => <String, CachedPriceHistory>{}, (stored) => stored)
      .run()
      .then((stored) {
        for (final MapEntry(:key, :value) in stored.entries) {
          if (_memory.containsKey(key)) continue;
          _memory[key] = value;
          _emit(key);
        }
      });

  /// Returns the history in memory, or null.
  CachedPriceHistory? peek(String key) => _memory[key];

  /// Returns true while a request for [key] runs.
  bool isLoading(String key) => _inFlight.containsKey(key);

  /// Loads the history from the network and caches it.
  ///
  /// With [ifOlderThan], a younger history in memory returns without a
  /// request. A failed request returns the error and keeps the cache.
  Future<Either<String, CachedPriceHistory>> refresh(
    Asset asset,
    Currency currency,
    MarketPeriod period, {
    Duration? ifOlderThan,
  }) {
    final key = keyOf(asset, currency, period);
    final cached = _memory[key];
    if (ifOlderThan != null &&
        cached != null &&
        cached.ageAt(_now()) < ifOlderThan) {
      return Future.value(Right(cached));
    }
    return _inFlight[key] ??= _load(
      key,
      period.paramsFor(asset),
    ).whenComplete(() {
      // A block body: returning the removed future would make the request
      // wait for itself.
      _inFlight.remove(key);
    });
  }

  /// Refreshes every period of [assets] that is not fresh, one request at
  /// a time, in the order of [assets]. Put the most important assets
  /// first.
  Future<void> prefetch(List<Asset> assets, Currency currency) async {
    await restore();
    for (final asset in assets) {
      for (final period in MarketPeriod.values) {
        if (_updates.isClosed) return;
        await refresh(asset, currency, period, ifOlderThan: period.freshFor);
      }
    }
  }

  Future<Either<String, CachedPriceHistory>> _load(
    String key,
    AssetPriceHistoryParams params,
  ) async {
    final requestedAt = _now();
    final Either<String, List<double>> result;
    try {
      result = await _fetch(params);
    } catch (error) {
      return Left('$error');
    }

    return result.flatMap<CachedPriceHistory>((prices) {
      if (prices.isEmpty) return const Left('Histórico vazio');
      final cached = _memory[key];
      // A history from a later request wins.
      if (cached != null && cached.fetchedAt.isAfter(requestedAt)) {
        return Right(cached);
      }
      final history = CachedPriceHistory(
        // The same list tells listeners that the points did not change.
        prices: cached != null && listEquals(cached.prices, prices)
            ? cached.prices
            : List.unmodifiable(prices),
        fetchedAt: requestedAt,
      );
      _memory[key] = history;
      _emit(key);
      // Storage is best effort: memory already holds the history.
      unawaited(_store.write(key, history).run());
      return Right(history);
    });
  }

  void _emit(String key) {
    if (!_updates.isClosed) _updates.add(key);
  }

  void dispose() => _updates.close();
}

/// The market history cache of the app.
final marketHistoryRepositoryProvider = Provider<MarketHistoryRepository>((
  ref,
) {
  final repository = MarketHistoryRepository(
    fetch: (params) => ref.read(priceHistoryFetcherProvider)(params),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// The history of one chart and the state of its request.
@immutable
class MarketHistoryState {
  const MarketHistoryState({this.history, this.loading = false, this.error});

  /// The cached or loaded history. Null before the first load.
  final CachedPriceHistory? history;

  /// True while a request runs. With a [history], the request is a silent
  /// background refresh.
  final bool loading;

  /// The error of the last request, kept only while there is no history.
  final String? error;

  bool get failed => history == null && !loading && error != null;
}

/// Serves the history of one asset and period: the cached history at once,
/// then a background refresh.
class MarketHistoryNotifier extends StateNotifier<MarketHistoryState> {
  MarketHistoryNotifier(
    this._repository,
    this._asset,
    this._currency,
    this._period,
  ) : _key = MarketHistoryRepository.keyOf(_asset, _currency, _period),
      super(const MarketHistoryState()) {
    state = MarketHistoryState(history: _repository.peek(_key), loading: true);
    _updates = _repository.updates
        .where((key) => key == _key)
        .listen((_) => _adopt(_repository.peek(_key)));
    _start();
  }

  final MarketHistoryRepository _repository;
  final Asset _asset;
  final Currency _currency;
  final MarketPeriod _period;
  final String _key;
  late final StreamSubscription<String> _updates;

  Future<void> _start() async {
    if (state.history == null) {
      await _repository.restore();
      if (!mounted) return;
      _adopt(_repository.peek(_key));
    }
    await refresh(ifOlderThan: MarketHistoryRepository.reopenGap);
  }

  /// Refreshes the history in the background. The current history stays
  /// on screen until the new one arrives.
  Future<void> refresh({Duration? ifOlderThan}) async {
    state = MarketHistoryState(history: state.history, loading: true);
    final result = await _repository.refresh(
      _asset,
      _currency,
      _period,
      ifOlderThan: ifOlderThan,
    );
    if (!mounted) return;
    state = result.fold(
      (error) => MarketHistoryState(
        history: state.history,
        error: state.history == null ? error : null,
      ),
      (history) => MarketHistoryState(history: history),
    );
  }

  void _adopt(CachedPriceHistory? history) {
    if (history == null || identical(history, state.history)) return;
    state = MarketHistoryState(history: history, loading: state.loading);
  }

  @override
  void dispose() {
    _updates.cancel();
    super.dispose();
  }
}

/// The history of one asset and period in the active currency.
final marketHistoryProvider = StateNotifierProvider.autoDispose
    .family<MarketHistoryNotifier, MarketHistoryState, (Asset, MarketPeriod)>((
      ref,
      key,
    ) {
      return MarketHistoryNotifier(
        ref.watch(marketHistoryRepositoryProvider),
        key.$1,
        ref.watch(currencyControllerProvider),
        key.$2,
      );
    });

/// Fills the market history cache for [assets] in the active currency,
/// without blocking the caller.
void prefetchMarketHistory(WidgetRef ref, List<Asset> assets) {
  final repository = ref.read(marketHistoryRepositoryProvider);
  final currency = ref.read(currencyControllerProvider);
  unawaited(repository.prefetch(assets, currency));
}
