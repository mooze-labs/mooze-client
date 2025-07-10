import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/core/repositories/mnemonic_repository.dart';

class MnemonicController {
  final MnemonicRepository _repository;

  MnemonicController({required MnemonicRepository repository})
    : _repository = repository;

  TaskEither<String, Option<String>> getMnemonic() {
    return _repository.getMnemonic();
  }

  TaskEither<String, Unit> saveMnemonic(String mnemonic) {
    return _repository.saveMnemonic(mnemonic);
  }
}
