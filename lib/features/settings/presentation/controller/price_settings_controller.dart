import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/prices/settings/price_settings_repository.dart';
import 'package:mooze_mobile/shared/prices/models.dart';

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

  TaskEither<String, PriceServiceConfig> getPriceSource() {
    return _priceSettingsRepository.getPriceServiceConfig();
  }
}
