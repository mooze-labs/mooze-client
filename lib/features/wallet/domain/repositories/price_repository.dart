import 'package:fpdart/fpdart.dart';

abstract class PriceRepository {
  TaskEither<String, Option<double>> getCoinPrice(String coin, String currency);
}
