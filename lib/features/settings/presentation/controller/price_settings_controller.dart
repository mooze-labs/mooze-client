import 'package:fpdart/fpdart.dart';

import '../../domains/repositories/price_settings_repository.dart';

class PriceSettingsController {
  final PriceSettingsRepository _priceSettingsRepository;

  PriceSettingsController({
    required PriceSettingsRepository priceSettingsRepository,
  }) : _priceSettingsRepository = priceSettingsRepository;

  TaskEither<String, Unit> setPriceSource(PriceSource source) {
    return _priceSettingsRepository.setPriceSource(source);
  }

  TaskEither<String, Unit> setPriceCurrency(Currency currency) {
    return _priceSettingsRepository.setPriceCurrency(currency);
  }

  TaskEither<String, PriceSource> getPriceSource() {
    return _priceSettingsRepository.getPriceSource();
  }

  TaskEither<String, Currency> getPriceCurrency() {
    return _priceSettingsRepository.getPriceCurrency();
  }
}
