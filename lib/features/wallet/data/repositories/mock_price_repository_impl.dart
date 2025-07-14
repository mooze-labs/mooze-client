import 'package:fpdart/fpdart.dart';

import '../../domain/repositories/price_repository.dart';

class MockPriceRepositoryImpl extends PriceRepository {
  @override
  TaskEither<String, Option<double>> getCoinPrice(
    String coin,
    String currency,
  ) {
    if (currency == "BRL") {
      return TaskEither.right(Option.of(630000.0));
    }

    if (currency == "USD") {
      return TaskEither.right(Option.of(109000.0));
    }

    return TaskEither.left("Currency not supported");
  }
}
