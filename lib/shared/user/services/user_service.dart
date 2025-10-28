import 'package:fpdart/fpdart.dart';

import '../entities.dart';

abstract class UserService {
  TaskEither<String, User> getUser();
  TaskEither<String, bool> validateReferralCode(String referralCode);
  TaskEither<String, Unit> addReferral(String referralCode);
}
