import 'package:fpdart/fpdart.dart';

import '../../domain/repositories/price_repository.dart';

class PriceController {
  final PriceRepository _priceRepository;

  PriceController(this._priceRepository);

  TaskEither<String, Option<double>> getPrice(String coin, String currency) {
    return _priceRepository.getCoinPrice(coin, currency);
  }
}
