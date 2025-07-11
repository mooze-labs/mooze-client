import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/key_management/mnemonic_store.dart';

class MnemonicController {
  final MnemonicStore _repository;

  MnemonicController({required MnemonicStore repository})
    : _repository = repository;

  TaskEither<String, Option<String>> getMnemonic() {
    return _repository.getMnemonic();
  }

  TaskEither<String, Unit> saveMnemonic(String mnemonic) {
    return _repository.saveMnemonic(mnemonic);
  }
}
