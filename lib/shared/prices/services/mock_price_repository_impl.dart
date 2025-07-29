import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../models.dart';

import 'price_service.dart';

class MockPriceServiceImpl extends PriceService {
  final Currency _currency;

  MockPriceServiceImpl(Currency currency) : _currency = currency;

  @override
  TaskEither<String, Option<double>> getCoinPrice(Asset asset, {Currency? optionalCurrency}) {
    if (_currency == Currency.brl) {
      return TaskEither.right(Option.of(630000.0));
    }

    if (_currency == Currency.usd) {
      return TaskEither.right(Option.of(109000.0));
    }

    return TaskEither.left("Currency not supported");
  }
}
