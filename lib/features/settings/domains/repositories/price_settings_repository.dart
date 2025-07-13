import 'package:fpdart/fpdart.dart';

enum Currency { brl, usd }

enum PriceSource { coingecko, mock }

abstract class PriceSettingsRepository {
  TaskEither<String, Unit> setPriceSource(PriceSource source);
  TaskEither<String, Unit> setPriceCurrency(Currency currency);

  TaskEither<String, PriceSource> getPriceSource();
  TaskEither<String, Currency> getPriceCurrency();
}
