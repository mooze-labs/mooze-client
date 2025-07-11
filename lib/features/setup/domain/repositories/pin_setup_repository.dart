import 'package:fpdart/fpdart.dart';

abstract class PinSetupRepository {
  TaskEither<String, Unit> createPin(String pin);
  TaskEither<String, bool> validatePin(String pin);
}
