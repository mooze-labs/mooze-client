import 'package:mooze_mobile/shared/entities/asset.dart';

import '../models/price_service_config.dart';

class PriceQuote {
  final Asset asset;
  final Currency currency;
  final double price;
  final DateTime fetchedAt;

  const PriceQuote({
    required this.asset,
    required this.currency,
    required this.price,
    required this.fetchedAt,
  });

  Duration get age => DateTime.now().difference(fetchedAt);
}

class PriceQuotes {
  final Currency currency;
  final Map<Asset, PriceQuote> quotes;
  final DateTime? lastSuccessAt;
  final bool warming;
  final bool refreshing;

  const PriceQuotes({
    required this.currency,
    required this.quotes,
    required this.lastSuccessAt,
    required this.warming,
    required this.refreshing,
  });

  factory PriceQuotes.initial(Currency currency) => PriceQuotes(
        currency: currency,
        quotes: const {},
        lastSuccessAt: null,
        warming: true,
        refreshing: false,
      );

  double? priceFor(Asset asset) => quotes[asset]?.price;

  PriceQuote? quoteFor(Asset asset) => quotes[asset];

  PriceQuotes copyWith({
    Currency? currency,
    Map<Asset, PriceQuote>? quotes,
    DateTime? lastSuccessAt,
    bool? warming,
    bool? refreshing,
  }) =>
      PriceQuotes(
        currency: currency ?? this.currency,
        quotes: quotes ?? this.quotes,
        lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
        warming: warming ?? this.warming,
        refreshing: refreshing ?? this.refreshing,
      );
}
