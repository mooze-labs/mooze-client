import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../api/binance.dart';
import '../models/price_service_config.dart';
import 'price_service.dart';

class BinancePriceService extends PriceService {
  final BinanceApi _api = BinanceApi();
  final Currency _defaultCurrency;

  BinancePriceService(Currency defaultCurrency) : _defaultCurrency = defaultCurrency;

  String get currency => _defaultCurrency.name;

  @override
  TaskEither<String, Option<double>> getCoinPrice(Asset asset, {Currency? optionalCurrency}) {
    final currency = (optionalCurrency == null)
        ? _defaultCurrency
        : optionalCurrency;

    if (asset == Asset.depix && currency == Currency.brl) {
      return TaskEither.right(Option<double>.of(1.0));
    }

    if (asset == Asset.usdt && currency == Currency.usd) {
      return TaskEither.right(Option<double>.of(1.0));
    }

    if (asset == Asset.depix && currency == Currency.usd) {
      return _extractBidPrice("USDTBRL").flatMap((opt) =>
          TaskEither.right(opt.map((f) => 1.0 / f)));
    }

    if (asset == Asset.btc) {
      switch (currency) {
        case Currency.brl:
          return _extractBidPrice("BTCBRL");
        case Currency.usd:
          return _extractBidPrice("BTCUSDT");
      }
    }

    if (asset == Asset.usdt && currency == Currency.brl) {
      return _extractBidPrice("USDTBRL");
    }

    return TaskEither.left("Unsupported asset/currency combination");
  }

  TaskEither<String, Option<double>> _extractBidPrice(String symbol) {
    final cache = BinancePriceCache();
    final TaskEither<String, Option<double>> brlInDollars = cache
        .getCachedPrices(_api)
        .map(
            (fetched) =>
            fetched
                .filter((i) => i["symbol"] == symbol)
                .head
                .fold(
                    () => Option<double>.none(),
                    (info) =>
                    info.extract("bidPrice").fold(
                            () => Option<double>.none(),
                            (n) => Option.fromNullable(double.tryParse(n))
                    )
            )
    );

    return brlInDollars;
  }
}

class BinanceDailyPriceVariationService extends DailyPriceVariationService {
  final BinanceApi _api = BinanceApi();
  final Currency _defaultCurrency;

  BinanceDailyPriceVariationService(Currency defaultCurrency) : _defaultCurrency = defaultCurrency;

  @override
  TaskEither<String, double> getPercentageVariation(Asset asset, {Currency? optionalCurrency}) {
    final currency = (optionalCurrency != null) ? optionalCurrency : _defaultCurrency;

    if (asset == Asset.depix && currency == Currency.brl) {
      return TaskEither.right(0.0);
    }

    if (asset == Asset.usdt && currency == Currency.usd) {
      return TaskEither.right(0.0);
    }

    if (asset == Asset.depix && currency == Currency.usd) {
      return _extractPriceChangePercent("USDTBRL").map((percent) => -percent);
    }

    if (asset == Asset.btc) {
      switch (currency) {
        case Currency.brl:
          return _extractPriceChangePercent("BTCBRL");
        case Currency.usd:
          return _extractPriceChangePercent("BTCUSDT");
      }
    }

    if (asset == Asset.usdt && currency == Currency.brl) {
      return _extractPriceChangePercent("USDTBRL");
    }

    return TaskEither.left("Unsupported asset/currency combination");
  }

  TaskEither<String, double> _extractPriceChangePercent(String symbol) {
    final cache = BinancePriceCache();
    final TaskEither<String, double> priceChangePercent = cache
        .getCachedPrices(_api)
        .map(
            (fetched) =>
            fetched
                .filter((i) => i["symbol"] == symbol)
                .head
                .fold(
                    () => 0.0,
                    (info) =>
                    info.extract("priceChangePercent").fold(
                            () => 0.0,
                            (n) => double.tryParse(n) ?? 0.0
                    )
            )
    );

    return priceChangePercent;
  }

  @override
  TaskEither<String, List<double>> get24hrKlines(Asset asset, {Currency? optionalCurrency}) {
    final currency = (optionalCurrency != null) ? optionalCurrency : _defaultCurrency;

    if (asset == Asset.depix && currency == Currency.brl) {
      return TaskEither.right(List.filled(24, 1.0));
    }

    if (asset == Asset.usdt && currency == Currency.usd) {
      // USDT/USD should be stable around 1.0, return flat line
      return TaskEither.right(List.filled(24, 1.0));
    }

    if (asset == Asset.depix && currency == Currency.usd) {
      return _get24hrKlinesForSymbol("USDTBRL").map((prices) => 
          prices.map((price) => 1.0 / price).toList());
    }

    if (asset == Asset.btc) {
      switch (currency) {
        case Currency.brl:
          return _get24hrKlinesForSymbol("BTCBRL");
        case Currency.usd:
          return _get24hrKlinesForSymbol("BTCUSDT");
      }
    }

    if (asset == Asset.usdt && currency == Currency.brl) {
      return _get24hrKlinesForSymbol("USDTBRL");
    }

    return TaskEither.left("Unsupported asset/currency combination");
  }

  TaskEither<String, List<double>> _get24hrKlinesForSymbol(String symbol) {
    final now = DateTime.now();
    final startTime = now.subtract(Duration(hours: 24));
    final cache = BinancePriceCache();
    
    return cache.getCachedKlines(
      _api,
      symbol, 
      "1h", 
      startTime.millisecondsSinceEpoch, 
      now.millisecondsSinceEpoch
    ).map((klinesList) {
      // First pass: extract all valid close prices
      final validPrices = <double>[];
      for (final kline in klinesList) {
        final price = double.tryParse(kline[4].toString());
        if (price != null) {
          validPrices.add(price);
        }
      }
      
      // Calculate average of valid prices
      final average = validPrices.isNotEmpty 
          ? validPrices.reduce((a, b) => a + b) / validPrices.length
          : 0.0;
      
      // Second pass: build final list with average fallback
      return klinesList.map((kline) {
        return double.tryParse(kline[4].toString()) ?? average;
      }).toList();
    });
  }
}