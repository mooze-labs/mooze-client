import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

abstract class PriceService {
  TaskEither<String, Option<double>> getCoinPrice(Asset asset);
}
