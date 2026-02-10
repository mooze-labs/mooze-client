import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../models.dart';

abstract class PriceService {
  String get currency;
  TaskEither<String, Option<double>> getCoinPrice(
    Asset asset, {
    Currency? optionalCurrency,
  });
}

enum KlineInterval {
  oneHour('1h'),
  fourHours('4h'),
  oneDay('1d'),
  oneWeek('1w'),
  oneMonth('1M');

  const KlineInterval(this.value);
  final String value;
}

abstract class DailyPriceVariationService {
  TaskEither<String, double> getPercentageVariation(
    Asset asset, {
    Currency? optionalCurrency,
  });
  TaskEither<String, List<double>> get24hrKlines(
    Asset asset, {
    Currency? optionalCurrency,
  });
  TaskEither<String, List<double>> getKlinesForPeriod(
    Asset asset,
    KlineInterval interval,
    int periodInDays, {
    Currency? optionalCurrency,
  });
}
