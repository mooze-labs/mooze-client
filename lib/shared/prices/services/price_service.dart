import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../models.dart';

abstract class PriceService {
  TaskEither<String, Option<double>> getCoinPrice(Asset asset, {Currency? optionalCurrency});
}

abstract class DailyPriceVariationService {
  TaskEither<String, double> getPercentageVariation(Asset asset, {Currency? optionalCurrency});
  TaskEither<String, List<double>> get24hrKlines(Asset asset, {Currency? optionalCurrency});
}
