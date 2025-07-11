import 'package:fpdart/fpdart.dart';

abstract class MnemonicStore {
  TaskEither<String, Unit> saveMnemonic(String mnemonic);
  TaskEither<String, Option<String>> getMnemonic();
}
