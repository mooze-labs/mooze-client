import 'package:fpdart/fpdart.dart';

abstract class PinSetupRepository {
  TaskEither<String, Unit> savePin(String pin);
  TaskEither<String, bool> validatePin(String pin);
}
