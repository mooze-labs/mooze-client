import 'package:fpdart/fpdart.dart';

abstract class PriceSettingsRepository {
  TaskEither<String, Unit> setPriceSource(String source);
  TaskEither<String, Unit> setPriceCurrency(String currency);

  TaskEither<String, String> getPriceSource();
  TaskEither<String, String> getPriceCurrency();
}
