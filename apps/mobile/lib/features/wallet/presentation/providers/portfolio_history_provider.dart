import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_history_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_period.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';

/// Base units per whole unit of every asset, as in the wallet totals.
const double _unitsPerCoin = 100000000;

/// The value of the current holdings across a period, oldest first.
@immutable
class PortfolioHistory {
  const PortfolioHistory({required this.values, required this.end});

  /// Fiat value at each point.
  final List<double> values;

  /// Time of the last point.
  final DateTime end;
}

final portfolioHistoryProvider = Provider.autoDispose
    .family<AsyncValue<PortfolioHistory?>, MarketPeriod>((ref, period) {
      final balances = ref.watch(allBalancesProvider).valueOrNull;
      if (balances == null) return const AsyncValue.loading();
      final quotes = ref.watch(priceQuotesProvider);

      final holdings = <(double coins, List<double>? prices, double? spot)>[];
      var loading = false;
      DateTime? end;
      for (final asset in ref.watch(allAssetsProvider)) {
        final balance = balances[asset] ?? BigInt.zero;
        if (balance <= BigInt.zero) continue;
        final state = ref.watch(marketHistoryProvider((asset, period)));
        final history = state.history;
        if (history == null && state.loading) loading = true;
        if (history != null &&
            (end == null || history.fetchedAt.isAfter(end))) {
          end = history.fetchedAt;
        }
        holdings.add((
          balance.toDouble() / _unitsPerCoin,
          history?.prices,
          quotes.priceFor(asset),
        ));
      }

      if (holdings.isEmpty) return const AsyncValue.data(null);
      // Wait for every held asset, so the line does not jump as they arrive.
      if (loading) return const AsyncValue.loading();

      final lengths = [
        for (final (_, prices, _) in holdings)
          if (prices != null) prices.length,
      ];
      if (lengths.isEmpty) {
        return AsyncValue.error('No price history', StackTrace.current);
      }
      final length = lengths.reduce(math.min);
      if (length < 2) {
        return AsyncValue.error('Price history too short', StackTrace.current);
      }

      final values = List<double>.generate(length, (i) {
        var total = 0.0;
        for (final (coins, prices, spot) in holdings) {
          final double? price;
          if (prices == null) {
            price = spot;
          } else {
            final point = prices[prices.length - length + i];
            final last = prices.last;
            price = spot != null && last > 0 ? point * spot / last : point;
          }
          if (price != null) total += coins * price;
        }
        return total;
      });

      return AsyncValue.data(
        PortfolioHistory(values: values, end: end ?? DateTime.now()),
      );
    });

/// Refreshes, in the background, the price histories of the held assets
/// for [period] that are older than [MarketHistoryRepository.reopenGap], as
/// a market sheet does when it opens. The chart keeps its history until
/// the new one arrives.
void refreshPortfolioHistory(WidgetRef ref, MarketPeriod period) {
  final balances = ref.read(allBalancesProvider).valueOrNull;
  if (balances == null) return;
  for (final asset in ref.read(allAssetsProvider)) {
    if ((balances[asset] ?? BigInt.zero) <= BigInt.zero) continue;
    unawaited(
      ref
          .read(marketHistoryProvider((asset, period)).notifier)
          .refresh(ifOlderThan: MarketHistoryRepository.reopenGap),
    );
  }
}
