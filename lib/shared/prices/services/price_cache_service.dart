import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import '../models/cached_price_data.dart';
import '../models/price_service_config.dart';

class PriceCacheService {
  static const String _keyPrefix = 'cached_price_';

  String _getCacheKey(Asset asset, Currency currency) {
    return '${_keyPrefix}${asset.id}_${currency.name}';
  }

  TaskEither<String, Unit> cachePrice(
    Asset asset,
    double price,
    Currency currency,
  ) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final cachedData = CachedPriceData(
        price: price,
        timestamp: DateTime.now(),
        currency: currency.name,
        assetId: asset.id,
      );

      final key = _getCacheKey(asset, currency);
      await sharedPreferences.setString(key, cachedData.toJsonString());

      return unit;
    }, (error, stackTrace) => 'Erro ao salvar preço no cache: $error');
  }

  TaskEither<String, Option<CachedPriceData>> getCachedPrice(
    Asset asset,
    Currency currency,
  ) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final key = _getCacheKey(asset, currency);
      final cachedString = sharedPreferences.getString(key);

      if (cachedString == null) {
        return Option<CachedPriceData>.none();
      }

      try {
        final cachedData = CachedPriceData.fromJsonString(cachedString);
        return Option.of(cachedData);
      } catch (e) {
        await sharedPreferences.remove(key);
        return Option<CachedPriceData>.none();
      }
    }, (error, stackTrace) => 'Erro ao recuperar preço do cache: $error');
  }

  TaskEither<String, Option<double>> getValidCachedPrice(
    Asset asset,
    Currency currency,
  ) {
    return getCachedPrice(asset, currency).map(
      (cachedOption) => cachedOption.fold(
        () => Option<double>.none(),
        (cached) =>
            cached.isValid ? Option.of(cached.price) : Option<double>.none(),
      ),
    );
  }

  TaskEither<String, Option<double>> getEmergencyCachedPrice(
    Asset asset,
    Currency currency,
  ) {
    return getCachedPrice(asset, currency).map(
      (cachedOption) => cachedOption.fold(
        () => Option<double>.none(),
        (cached) =>
            cached.isRecentEnough
                ? Option.of(cached.price)
                : Option<double>.none(),
      ),
    );
  }

  TaskEither<String, Unit> cleanExpiredCache() {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final allKeys = sharedPreferences.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith(_keyPrefix));

      final now = DateTime.now();

      for (final key in cacheKeys) {
        final cachedString = sharedPreferences.getString(key);
        if (cachedString != null) {
          try {
            final cachedData = CachedPriceData.fromJsonString(cachedString);
            final difference = now.difference(cachedData.timestamp);

            if (difference.inHours > 24) {
              await sharedPreferences.remove(key);
            }
          } catch (e) {
            await sharedPreferences.remove(key);
          }
        }
      }

      return unit;
    }, (error, stackTrace) => 'Erro ao limpar cache expirado: $error');
  }
}
