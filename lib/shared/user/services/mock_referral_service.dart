import 'package:fpdart/fpdart.dart';

import 'referral_service.dart';

class MockReferralService implements ReferralService {
  bool _isValidReferralCode = true;
  bool _shouldFail = false;

  void setIsValidReferralCode(bool isValid) {
    _isValidReferralCode = isValid;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  TaskEither<String, bool> validateReferralCode(String referralCode) {
    return TaskEither(() async {
      if (_shouldFail) {
        return left('Failed to validate referral code');
      }
      return right(_isValidReferralCode);
    });
  }
}