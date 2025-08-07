import 'package:fpdart/fpdart.dart';

abstract class AddressGeneratorRepository {
  TaskEither<String, String> generateNewAddress();
}
