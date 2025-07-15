import 'package:fpdart/fpdart.dart';

import '../entities.dart';

abstract class RemoteAuthenticationRepository {
  TaskEither<String, AuthenticationChallenge> requestLoginChallenge(
    String userId,
    String pubKey,
  );
  TaskEither<String, String> signChallenge(AuthenticationChallenge challenge);
}
