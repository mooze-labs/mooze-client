import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import '../models/price_service_config.dart';
import 'price_service.dart';
import 'price_cache_service.dart';

class CachedPriceService extends PriceService {
  final PriceService _wrappedService;
  final PriceCacheService _cacheService;
  final Currency _currency;

  CachedPriceService(this._wrappedService, this._currency)
    : _cacheService = PriceCacheService();

  @override
  String get currency => _currency.name;

  @override
  TaskEither<String, Option<double>> getCoinPrice(
    Asset asset, {
    Currency? optionalCurrency,
  }) {
    final targetCurrency = optionalCurrency ?? _currency;

    return _tryGetFreshPrice(asset, targetCurrency).flatMap(
      (freshPriceOption) => freshPriceOption.fold(
        () => _tryGetCachedPrice(asset, targetCurrency),
        (freshPrice) => _saveToCache(asset, freshPrice, targetCurrency)
            .map((_) => Option.of(freshPrice))
            .alt(() => TaskEither.right(Option.of(freshPrice))),
      ),
    );
  }

  TaskEither<String, Option<double>> _tryGetFreshPrice(
    Asset asset,
    Currency currency,
  ) {
    return _wrappedService
        .getCoinPrice(asset, optionalCurrency: currency)
        .alt(() => TaskEither.right(Option<double>.none()));
  }

  TaskEither<String, Option<double>> _tryGetCachedPrice(
    Asset asset,
    Currency currency,
  ) {
    return _cacheService
        .getValidCachedPrice(asset, currency)
        .flatMap(
          (validCacheOption) => validCacheOption.fold(
            () => _cacheService.getEmergencyCachedPrice(asset, currency),
            (cachedPrice) => TaskEither.right(Option.of(cachedPrice)),
          ),
        );
  }

  TaskEither<String, Unit> _saveToCache(
    Asset asset,
    double price,
    Currency currency,
  ) {
    return _cacheService.cachePrice(asset, price, currency);
  }

  TaskEither<String, Unit> cleanExpiredCache() {
    return _cacheService.cleanExpiredCache();
  }

  TaskEither<String, bool> hasCachedPrice(
    Asset asset, {
    Currency? optionalCurrency,
  }) {
    final targetCurrency = optionalCurrency ?? _currency;
    return _cacheService
        .getCachedPrice(asset, targetCurrency)
        .map((cachedOption) => cachedOption.isSome());
  }

  TaskEither<String, Option<int>> getCacheAgeInMinutes(
    Asset asset, {
    Currency? optionalCurrency,
  }) {
    final targetCurrency = optionalCurrency ?? _currency;
    return _cacheService
        .getCachedPrice(asset, targetCurrency)
        .map(
          (cachedOption) =>
              cachedOption.fold(() => Option<int>.none(), (cached) {
                final now = DateTime.now();
                final ageInMinutes = now.difference(cached.timestamp).inMinutes;
                return Option.of(ageInMinutes);
              }),
        );
  }
}
