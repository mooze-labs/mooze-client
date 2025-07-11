import 'package:fpdart/fpdart.dart';
import '../../../domain/repositories/mnemonic_repository.dart';

class MnemonicController {
  final MnemonicRepository _repository;

  MnemonicController({required MnemonicRepository repository})
    : _repository = repository;

  TaskEither<String, Unit> saveMnemonic(String mnemonic) {
    return _repository.saveMnemonic(mnemonic);
  }

  bool validateMnemonic(String mnemonic) {
    return _repository.validateMnemonic(mnemonic);
  }

  String generateMnemonic(bool extendedPhrase) {
    return _repository.generateMnemonic(extendedPhrase);
  }
}
