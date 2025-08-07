import 'package:fpdart/fpdart.dart';

import '../../domain/repositories/price_repository.dart';
import '../datasources/coingecko_data_source.dart';

class CoingeckoPriceRepositoryImpl extends PriceRepository {
  final CoingeckoDataSource _coingeckoDataSource = CoingeckoDataSource();

  CoingeckoPriceRepositoryImpl();

  @override
  TaskEither<String, Option<double>> getCoinPrice(
    String coin,
    String currency,
  ) {
    return _coingeckoDataSource
        .getCoinPrice([coin], currency)
        .map(
          (fetched) => fetched.match(
            () => Option.none(),
            (some) => Option.fromNullable(some[coin]?[currency]),
          ),
        );
  }
}
