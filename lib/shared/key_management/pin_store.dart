import 'package:fpdart/fpdart.dart';

abstract class PinStore {
  TaskEither<String, Unit> save(String pin);
  TaskEither<String, bool> validate(String pin);
  Task<bool> hasPin();
}
