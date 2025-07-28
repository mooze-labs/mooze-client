import 'package:fpdart/fpdart.dart';
import '../../domain/repositories.dart';

class AddressGeneratorController {
  final AddressGeneratorRepository _repository;

  AddressGeneratorController(AddressGeneratorRepository repository)
    : _repository = repository;

  TaskEither<String, String> newLiquidAddress() {
    return _repository.generateNewAddress();
  }
}
