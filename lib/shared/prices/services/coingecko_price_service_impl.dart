import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../api/coingecko.dart';
import '../models.dart';

import 'price_service.dart';

class CoingeckoPriceServiceImpl extends PriceService {
  final CoingeckoApi _coingeckoDataSource = CoingeckoApi();
  final Currency _currency;

  CoingeckoPriceServiceImpl(Currency currency) : _currency = currency;

  @override
  String get currency => _currency.name;

  @override
  TaskEither<String, Option<double>> getCoinPrice(
    Asset asset, {
    Currency? optionalCurrency,
  }) {
    final currency = optionalCurrency ?? _currency;
    if (asset == Asset.depix && currency == Currency.brl) {
      return TaskEither.right(Option<double>.of(1.0));
    }

    if (asset == Asset.usdt && currency == Currency.usd) {
      return TaskEither.right(Option<double>.of(1.0));
    }

    if (asset == Asset.depix && currency == Currency.usd) {
      final brlInDollars = _coingeckoDataSource
          .getCoinPrice(["tether"], "brl")
          .map(
            (fetched) => fetched.match(
              () => Option<double>.none(),
              (some) =>
                  Option<double>.fromNullable(some["tether"]?["brl"] as double),
            ),
          )
          .flatMap((dollarPriceOption) {
            return dollarPriceOption.match(
              () => TaskEither.right(Option<double>.none()),
              (dollarPrice) =>
                  TaskEither.right(Option<double>.of(1.0 / dollarPrice)),
            );
          });

      return brlInDollars;
    }

    return TaskEither.fromEither(_convertToCoingeckoTicker(asset)).flatMap((
      ticker,
    ) {
      return _coingeckoDataSource
          .getCoinPrice([ticker], _currency.name)
          .map(
            (fetched) => fetched.match(
              () => Option.none(),
              (some) => Option.fromNullable(some[ticker]?[_currency.name]),
            ),
          );
    });
  }

  Either<String, String> _convertToCoingeckoTicker(Asset asset) {
    switch (asset) {
      case Asset.btc || Asset.lbtc:
        return right("bitcoin");
      case Asset.usdt:
        return right("tether");
      case Asset.depix:
        return left("Depix is not a valid Coingecko asset.");
    }
  }
}
