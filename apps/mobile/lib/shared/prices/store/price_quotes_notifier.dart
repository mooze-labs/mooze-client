import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../models/price_service_config.dart';
import '../providers/currency_controller_provider.dart';
import '../services/hybrid_price_service.dart';
import '../services/price_cache_service.dart';
import '../settings/price_settings_repository.dart';
import 'price_quote.dart';
import 'price_sync_coordinator.dart';


class PriceQuotesNotifier extends StateNotifier<PriceQuotes> {
  PriceQuotesNotifier(this._ref) : super(PriceQuotes.initial(Currency.brl)) {
    _bootstrap();
  }

  final Ref _ref;
  final PriceCacheService _cache = PriceCacheService();
  HybridPriceService? _service;
  bool _disposed = false;
  int _generation = 0;
  Completer<void>? _firstReady;

  static const List<Asset> assets = [
    Asset.btc,
    Asset.usdt,
    Asset.depix,
    Asset.lbtc,
  ];

  Future<void> waitFirstReady() async {
    if (!state.warming) return;
    _firstReady ??= Completer<void>();
    return _firstReady!.future;
  }

  Future<void> _bootstrap() async {
    _ref.listen<Currency>(currencyControllerProvider, (prev, next) {
      if (prev == next) return;
      unawaited(_swapCurrency(next));
    });

    final config = await PriceSettingsRepositoryImpl()
        .getPriceServiceConfig()
        .run();
    if (_disposed) return;

    final currency = config.fold((_) => Currency.brl, (c) => c.currency);
    final source = config.fold((_) => PriceSource.coingecko, (c) => c.priceSource);

    await _initializeForCurrency(currency, source);

    _ref.read(priceSyncCoordinatorProvider);
  }

  Future<void> _initializeForCurrency(Currency currency, PriceSource source) async {
    _service = HybridPriceService(currency, source);
    final disk = await _readAllFromCache(currency);
    if (_disposed) return;

    state = state.copyWith(
      currency: currency,
      quotes: disk,
      warming: false,
    );
    _signalFirstReady();

    unawaited(refresh());
  }

  /// Switches the quotes to [next] without waiting for the network.
  ///
  /// In the same frame, the known prices are converted with the exchange
  /// rate they carry (see [_convertQuotes]), so the portfolio shows the new
  /// currency at once and never shows prices of the old currency under the
  /// new symbol. Then the live prices are fetched, and the prices cached on
  /// disk for [next] fill any gap meanwhile. A newer quote always wins.
  Future<void> _swapCurrency(Currency next) async {
    if (_disposed) return;
    _service = HybridPriceService(next, PriceSource.coingecko);

    state = state.copyWith(
      currency: next,
      quotes: _convertQuotes(state.quotes, next),
    );
    unawaited(refresh());

    final disk = await _readAllFromCache(next);
    // A later switch owns the state now.
    if (_disposed || state.currency != next) return;

    final merged = Map<Asset, PriceQuote>.from(state.quotes);
    disk.forEach((asset, cached) {
      final current = merged[asset];
      if (current == null || cached.fetchedAt.isAfter(current.fetchedAt)) {
        merged[asset] = cached;
      }
    });
    state = state.copyWith(quotes: merged);
  }

  /// Converts [quotes] to [next] with the exchange rate they carry.
  ///
  /// Each currency has an asset pegged to it: USDT to the dollar and DePix
  /// to the real. The price of that asset in the old currency is the price
  /// of one unit of [next], so every price divides by it. Without that
  /// price, nothing converts and only the pegged asset is known.
  static Map<Asset, PriceQuote> _convertQuotes(
    Map<Asset, PriceQuote> quotes,
    Currency next,
  ) {
    final pegged = switch (next) {
      Currency.usd => Asset.usdt,
      Currency.brl => Asset.depix,
    };
    final rate = quotes[pegged];
    // Already in [next], for example after a switch back and forth.
    if (rate != null && rate.currency == next) return Map.of(quotes);

    final result = <Asset, PriceQuote>{};
    if (rate != null && rate.price > 0) {
      quotes.forEach((asset, quote) {
        result[asset] = PriceQuote(
          asset: asset,
          currency: next,
          price: quote.price / rate.price,
          fetchedAt: quote.fetchedAt,
        );
      });
    }
    result[pegged] = PriceQuote(
      asset: pegged,
      currency: next,
      price: 1,
      fetchedAt: rate?.fetchedAt ?? DateTime.now(),
    );
    return result;
  }

  Future<Map<Asset, PriceQuote>> _readAllFromCache(Currency currency) async {
    final result = <Asset, PriceQuote>{};
    for (final asset in assets) {
      final r = await _cache.getCachedPrice(asset, currency).run();
      r.fold((_) => null, (opt) {
        opt.fold(() => null, (cached) {
          result[asset] = PriceQuote(
            asset: asset,
            currency: currency,
            price: cached.price,
            fetchedAt: cached.timestamp,
          );
        });
      });
    }
    return result;
  }

  Future<void> refresh() async {
    final service = _service;
    if (service == null) return;
    if (_disposed) return;

    final myGen = ++_generation;
    final myCurrency = state.currency;
    state = state.copyWith(refreshing: true);

    final results = await Future.wait(assets.map((asset) async {
      try {
        final result =
            await service.getCoinPrice(asset, optionalCurrency: myCurrency).run();
        return result.fold<PriceQuote?>(
          (_) => null,
          (opt) => opt.fold(
            () => null,
            (price) => PriceQuote(
              asset: asset,
              currency: myCurrency,
              price: price,
              fetchedAt: DateTime.now(),
            ),
          ),
        );
      } catch (_) {
        return null;
      }
    }));

    if (_disposed) return;

    if (myGen != _generation) return;
    if (myCurrency != state.currency) return;

    final next = Map<Asset, PriceQuote>.from(state.quotes);
    var anyFresh = false;
    for (var i = 0; i < assets.length; i++) {
      final fresh = results[i];
      if (fresh != null) {
        next[assets[i]] = fresh;
        anyFresh = true;
      }
    }

    state = state.copyWith(
      quotes: next,
      lastSuccessAt: anyFresh ? DateTime.now() : state.lastSuccessAt,
      refreshing: false,
    );
    _signalFirstReady();
  }

  void _signalFirstReady() {
    final c = _firstReady;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final priceQuotesProvider =
    StateNotifierProvider<PriceQuotesNotifier, PriceQuotes>((ref) {
  ref.keepAlive();
  return PriceQuotesNotifier(ref);
});
