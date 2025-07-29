import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../models.dart';

abstract class PriceService {
  TaskEither<String, Option<double>> getCoinPrice(Asset asset, {Currency? optionalCurrency});
}
