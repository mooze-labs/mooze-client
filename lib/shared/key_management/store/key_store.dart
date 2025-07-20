import 'package:fpdart/fpdart.dart';

abstract class KeyStore {
  TaskEither<String, Unit> saveKey(String key, String value);
  TaskEither<String, Option<String>> getKey(String key);
}
