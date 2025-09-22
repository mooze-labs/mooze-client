import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import '../models/price_service_config.dart';
import 'price_service.dart';
import 'binance_price_service.dart';
import 'coingecko_price_service_impl.dart';
import 'cached_price_service.dart';
import '../../connectivity/providers/connectivity_provider.dart';

class HybridPriceService extends PriceService {
  final Currency _defaultCurrency;
  final PriceSource _primarySource;

  late final PriceService _primaryService;
  late final CachedPriceService _binanceService;
  late final CachedPriceService _coingeckoService;

  HybridPriceService(Currency currency, PriceSource primarySource)
    : _defaultCurrency = currency,
      _primarySource = primarySource {
    final binanceService = BinancePriceService(currency);
    final coingeckoService = CoingeckoPriceServiceImpl(currency);

    _binanceService = CachedPriceService(binanceService, currency);
    _coingeckoService = CachedPriceService(coingeckoService, currency);

    switch (primarySource) {
      case PriceSource.binance:
        _primaryService = _binanceService;
        break;
      case PriceSource.coingecko:
        _primaryService = _coingeckoService;
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
        return [_coingeckoService];
      case PriceSource.coingecko:
        return [_binanceService];
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

  TaskEither<String, Unit> cleanExpiredCache() {
    return _binanceService.cleanExpiredCache();
  }

  TaskEither<String, bool> hasCachedPrice(
    Asset asset, {
    Currency? optionalCurrency,
  }) {
    final targetCurrency = optionalCurrency ?? _defaultCurrency;
    final serviceToCheck =
        _primarySource == PriceSource.binance
            ? _binanceService
            : _coingeckoService;
    return serviceToCheck.hasCachedPrice(
      asset,
      optionalCurrency: targetCurrency,
    );
  }

  TaskEither<String, Option<int>> getCacheAgeInMinutes(
    Asset asset, {
    Currency? optionalCurrency,
  }) {
    final targetCurrency = optionalCurrency ?? _defaultCurrency;
    final serviceToCheck =
        _primarySource == PriceSource.binance
            ? _binanceService
            : _coingeckoService;
    return serviceToCheck.getCacheAgeInMinutes(
      asset,
      optionalCurrency: targetCurrency,
    );
  }

  TaskEither<String, Option<double>> getCoinPriceWithConnectivityUpdate(
    Asset asset, {
    Currency? optionalCurrency,
    Ref? ref,
  }) {
    return getCoinPrice(asset, optionalCurrency: optionalCurrency).map((
      result,
    ) {
      if (ref != null) {
        result.fold(
          () {
            hasCachedPrice(
              asset,
              optionalCurrency: optionalCurrency,
            ).run().then((cacheResult) {
              cacheResult.fold((error) => {}, (hasCache) {
                if (hasCache) {
                  ref.read(connectivityProvider.notifier).markOffline();
                }
              });
            });
          },
          (price) {
            ref.read(connectivityProvider.notifier).markOnline();
          },
        );
      }
      return result;
    });
  }
}
