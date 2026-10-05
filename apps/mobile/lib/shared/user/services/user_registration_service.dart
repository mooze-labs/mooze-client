import 'package:fpdart/fpdart.dart';

import '../entities.dart';

abstract class UserRegistrationService {
  TaskEither<String, User> createNewUser(
    String publicKey,
    String? referralCode,
  );
}
