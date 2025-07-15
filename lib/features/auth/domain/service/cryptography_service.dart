import 'package:fpdart/fpdart.dart';

abstract class CryptographyService {
  Either<String, String> signMessage(String message);
  TaskEither<String, String> getPublicKey();
}
