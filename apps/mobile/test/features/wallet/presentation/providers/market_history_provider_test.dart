import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_history_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_period.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _History = Either<String, List<double>>;

/// A network that answers each request when the test says so.
class _Network {
  final List<(AssetPriceHistoryParams, Completer<_History>)> requests = [];
  int running = 0;
  int maxRunning = 0;

  Future<_History> fetch(AssetPriceHistoryParams params) {
    final request = Completer<_History>();
    requests.add((params, request));
    running++;
    if (running > maxRunning) maxRunning = running;
    return request.future.whenComplete(() => running--);
  }

  /// Answers the oldest open request.
  void answer(_History history) =>
      requests.firstWhere((r) => !r.$2.isCompleted).$2.complete(history);
}

void main() {
  late _Network network;
  late DateTime now;

  MarketHistoryRepository repository() =>
      MarketHistoryRepository(fetch: network.fetch, now: () => now);

  String keyOf(MarketPeriod period) =>
      MarketHistoryRepository.keyOf(Asset.btc, Currency.brl, period);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    network = _Network();
    now = DateTime(2026, 11, 1, 12);
  });

  test('a loaded history is in memory and survives a restart', () async {
    final first = repository();
    final loading = first.refresh(Asset.btc, Currency.brl, MarketPeriod.day);
    network.answer(right([1, 2, 3]));
    final result = await loading;

    expect(result.getRight().toNullable()!.prices, [1, 2, 3]);
    expect(first.peek(keyOf(MarketPeriod.day))!.prices, [1, 2, 3]);
    // Storage writes in the background.
    await pumpEventQueue();

    final restarted = repository();
    expect(restarted.peek(keyOf(MarketPeriod.day)), isNull);
    await restarted.restore();
    final restored = restarted.peek(keyOf(MarketPeriod.day))!;
    expect(restored.prices, [1, 2, 3]);
    expect(restored.fetchedAt, now);
  });

  test('concurrent refreshes of one history share one request', () async {
    final cache = repository();
    final a = cache.refresh(Asset.btc, Currency.brl, MarketPeriod.day);
    final b = cache.refresh(Asset.btc, Currency.brl, MarketPeriod.day);
    expect(network.requests, hasLength(1));
    expect(cache.isLoading(keyOf(MarketPeriod.day)), isTrue);

    network.answer(right([5, 6]));
    expect(
      (await a).getRight().toNullable(),
      same((await b).getRight().toNullable()),
    );
    expect(cache.isLoading(keyOf(MarketPeriod.day)), isFalse);
  });

  test('a failed refresh keeps the cached history', () async {
    final cache = repository();
    final first = cache.refresh(Asset.btc, Currency.brl, MarketPeriod.week);
    network.answer(right([1, 2]));
    final cached = (await first).getRight().toNullable();

    now = now.add(const Duration(hours: 1));
    final second = cache.refresh(Asset.btc, Currency.brl, MarketPeriod.week);
    network.answer(left('timeout'));

    expect((await second).getLeft().toNullable(), 'timeout');
    expect(cache.peek(keyOf(MarketPeriod.week)), same(cached));
  });

  test(
    'an unchanged response keeps the cached list and moves the time',
    () async {
      final cache = repository();
      final first = cache.refresh(Asset.btc, Currency.brl, MarketPeriod.day);
      network.answer(right([1, 2, 3]));
      final before = (await first).getRight().toNullable()!;

      now = now.add(const Duration(minutes: 10));
      final second = cache.refresh(Asset.btc, Currency.brl, MarketPeriod.day);
      network.answer(right([1, 2, 3]));
      final after = (await second).getRight().toNullable()!;

      expect(after.prices, same(before.prices));
      expect(after.fetchedAt, now);
    },
  );

  test('a fresh history skips the request', () async {
    final cache = repository();
    final first = cache.refresh(Asset.btc, Currency.brl, MarketPeriod.day);
    network.answer(right([1, 2]));
    await first;

    now = now.add(const Duration(minutes: 1));
    await cache.refresh(
      Asset.btc,
      Currency.brl,
      MarketPeriod.day,
      ifOlderThan: MarketPeriod.day.freshFor,
    );
    expect(network.requests, hasLength(1));

    now = now.add(MarketPeriod.day.freshFor);
    final stale = cache.refresh(
      Asset.btc,
      Currency.brl,
      MarketPeriod.day,
      ifOlderThan: MarketPeriod.day.freshFor,
    );
    expect(network.requests, hasLength(2));
    network.answer(right([3, 4]));
    await stale;
  });

  test('a restore keeps a newer history that is already in memory', () async {
    final old = DateTime(2026, 10, 31);
    SharedPreferences.setMockInitialValues({
      'cached_price_history_${keyOf(MarketPeriod.day)}': CachedPriceHistory(
        prices: [9, 9],
        fetchedAt: old,
      ).toJsonString(),
    });
    final cache = repository();
    final loading = cache.refresh(Asset.btc, Currency.brl, MarketPeriod.day);
    network.answer(right([1, 2]));
    await loading;

    await cache.restore();
    expect(cache.peek(keyOf(MarketPeriod.day))!.prices, [1, 2]);
  });

  test('a restore drops histories older than the maximum age', () async {
    SharedPreferences.setMockInitialValues({
      'cached_price_history_${keyOf(MarketPeriod.month)}': CachedPriceHistory(
        prices: [1, 2],
        fetchedAt: now.subtract(
          MarketHistoryRepository.maxAge + const Duration(hours: 1),
        ),
      ).toJsonString(),
      'cached_price_history_${keyOf(MarketPeriod.week)}': 'not json',
    });
    final cache = repository();
    await cache.restore();

    expect(cache.peek(keyOf(MarketPeriod.month)), isNull);
    expect(cache.peek(keyOf(MarketPeriod.week)), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), isEmpty);
  });

  test('a prefetch loads every period in asset order, one request at a time, '
      'and skips fresh histories', () async {
    final cache = repository();
    final day = cache.refresh(Asset.usdt, Currency.brl, MarketPeriod.day);
    network.answer(right([1, 2]));
    await day;

    final prefetch = cache.prefetch([Asset.usdt, Asset.btc], Currency.brl);
    while (network.requests.any((r) => !r.$2.isCompleted) ||
        network.requests.length < 6) {
      await pumpEventQueue();
      if (network.requests.any((r) => !r.$2.isCompleted)) {
        network.answer(right([1, 2]));
      }
    }
    await prefetch;

    expect(network.maxRunning, 1);
    expect(
      [
        for (final (params, _) in network.requests.skip(1))
          (params.asset, params.periodInDays),
      ],
      [
        (Asset.usdt, 7),
        (Asset.usdt, 30),
        (Asset.btc, 1),
        (Asset.btc, 7),
        (Asset.btc, 30),
      ],
    );
  });
}
