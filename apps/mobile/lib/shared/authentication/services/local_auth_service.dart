import 'package:fpdart/fpdart.dart';

abstract class LocalAuthenticationService {
  TaskEither<String, Unit> savePin(String pin);
  TaskEither<String, bool> validatePin(String pin);
  Task<bool> isAuthenticated();
}
