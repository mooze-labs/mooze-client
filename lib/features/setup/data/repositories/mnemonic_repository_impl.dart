import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/key_management/store.dart';
import '../../domain/repositories/mnemonic_repository.dart';

class MnemonicRepositoryImpl implements MnemonicRepository {
  final MnemonicStore _mnemonicStore;

  MnemonicRepositoryImpl({required MnemonicStore mnemonicStore})
    : _mnemonicStore = mnemonicStore;

  @override
  TaskEither<String, Unit> saveMnemonic(String mnemonic) {
    return _mnemonicStore.saveMnemonic(mnemonic);
  }

  @override
  bool validateMnemonic(String mnemonic) {
    final splitMnemonic = mnemonic.trim().split(" ");
    if (splitMnemonic.length != 12 && splitMnemonic.length != 24) {
      return false;
    }

    return true;
  }

  @override
  String generateMnemonic(bool extendedPhrase) {
    return _mnemonicStore.generateMnemonic(extendedPhrase: extendedPhrase);
  }
}
