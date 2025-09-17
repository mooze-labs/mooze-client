import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import '../models/price_service_config.dart';
import 'price_service.dart';
import 'binance_price_service.dart';
import 'coingecko_price_service_impl.dart';
import 'mock_price_repository_impl.dart';

class HybridPriceService extends PriceService {
  final Currency _defaultCurrency;
  final PriceSource _primarySource;

  late final PriceService _primaryService;
  late final PriceService _binanceService;
  late final PriceService _coingeckoService;
  late final PriceService _mockService;

  HybridPriceService(Currency currency, PriceSource primarySource)
    : _defaultCurrency = currency,
      _primarySource = primarySource {
    _binanceService = BinancePriceService(currency);
    _coingeckoService = CoingeckoPriceServiceImpl(currency);
    _mockService = MockPriceServiceImpl(currency);

    switch (primarySource) {
      case PriceSource.binance:
        _primaryService = _binanceService;
        break;
      case PriceSource.coingecko:
        _primaryService = _coingeckoService;
        break;
      case PriceSource.mock:
        _primaryService = _mockService;
        break;
    }
  }

  @override
  String get currency => _defaultCurrency.name;

  @override
  TaskEither<String, Option<double>> getCoinPrice(
    Asset asset, {
    Currency? optionalCurrency,
  }) {
    final targetCurrency = optionalCurrency ?? _defaultCurrency;
    return _tryPrimaryService(asset, targetCurrency).flatMap(
      (result) => result.fold(
        () => _tryAlternativeServices(asset, targetCurrency),
        (price) => TaskEither.right(Option.of(price)),
      ),
    );
  }

  TaskEither<String, Option<double>> _tryPrimaryService(
    Asset asset,
    Currency currency,
  ) {
    return _primaryService
        .getCoinPrice(asset, optionalCurrency: currency)
        .flatMap(
          (result) => result.fold(
            () {
              return TaskEither.right(Option<double>.none());
            },
            (price) {
              return TaskEither.right(Option.of(price));
            },
          ),
        )
        .alt(() {
          return TaskEither.right(Option<double>.none());
        });
  }

  TaskEither<String, Option<double>> _tryAlternativeServices(
    Asset asset,
    Currency currency,
  ) {
    final alternativeServices = _getAlternativeServices();

    return _tryServicesInSequence(alternativeServices, asset, currency);
  }

  List<PriceService> _getAlternativeServices() {
    switch (_primarySource) {
      case PriceSource.binance:
        return [_coingeckoService, _mockService];
      case PriceSource.coingecko:
        return [_binanceService, _mockService];
      case PriceSource.mock:
        return [_binanceService, _coingeckoService];
    }
  }

  TaskEither<String, Option<double>> _tryServicesInSequence(
    List<PriceService> services,
    Asset asset,
    Currency currency,
  ) {
    if (services.isEmpty) {
      return TaskEither.right(Option<double>.none());
    }

    final currentService = services.first;
    final remainingServices = services.skip(1).toList();

    return currentService
        .getCoinPrice(asset, optionalCurrency: currency)
        .flatMap(
          (result) => result.fold(
            () => _tryServicesInSequence(remainingServices, asset, currency),
            (price) {
              return TaskEither.right(Option.of(price));
            },
          ),
        )
        .alt(() => _tryServicesInSequence(remainingServices, asset, currency));
  }
}
