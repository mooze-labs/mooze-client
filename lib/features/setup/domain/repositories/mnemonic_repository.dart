import 'package:fpdart/fpdart.dart';

abstract class MnemonicRepository {
  TaskEither<String, Unit> saveMnemonic(String mnemonic);
  bool validateMnemonic(String mnemonic);
  String generateMnemonic(bool extendedPhrase);
}
