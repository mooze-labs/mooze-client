import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cached_price_history.dart';

/// Keeps price histories in shared preferences, so they survive an app
/// restart.
///
/// Each history is one JSON entry under its own key. A history has a few
/// dozen points, so all entries together stay a few kilobytes.
class PriceHistoryCacheService {
  static const String _keyPrefix = 'cached_price_history_';

  String _storageKey(String key) => '$_keyPrefix$key';

  TaskEither<String, Unit> write(String key, CachedPriceHistory history) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(
        _storageKey(key),
        history.toJsonString(),
      );
      return unit;
    }, (error, stackTrace) => 'Erro ao salvar histórico no cache: $error');
  }

  /// Reads all histories younger than [maxAge] at [now], by key. It removes
  /// older and unreadable entries.
  TaskEither<String, Map<String, CachedPriceHistory>> readAll({
    required DateTime now,
    required Duration maxAge,
  }) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final histories = <String, CachedPriceHistory>{};
      final keys = sharedPreferences.getKeys().where(
        (key) => key.startsWith(_keyPrefix),
      );

      for (final storageKey in keys.toList()) {
        final cachedString = sharedPreferences.getString(storageKey);
        try {
          final history = CachedPriceHistory.fromJsonString(cachedString!);
          if (history.ageAt(now) > maxAge) {
            await sharedPreferences.remove(storageKey);
            continue;
          }
          histories[storageKey.substring(_keyPrefix.length)] = history;
        } catch (_) {
          await sharedPreferences.remove(storageKey);
        }
      }

      return histories;
    }, (error, stackTrace) => 'Erro ao recuperar históricos do cache: $error');
  }
}
