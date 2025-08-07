import 'package:fpdart/fpdart.dart';

abstract class ReferralService {
  TaskEither<String, bool> validateReferralCode(String referralCode);
}
