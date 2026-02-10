import 'package:fpdart/fpdart.dart';

import '../models.dart';

abstract class RemoteAuthenticationService {
  TaskEither<String, AuthChallenge> requestLoginChallenge();
  TaskEither<String, Session> signChallenge(AuthChallenge challenge);
}
