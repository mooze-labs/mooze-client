import 'package:fpdart/fpdart.dart';

abstract class SignatureClient {
  Either<String, String> signMessage(String message);
  TaskEither<String, String> getPublicKey();
}
