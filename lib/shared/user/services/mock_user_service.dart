import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import 'user_service.dart';

class MockUserService implements UserService {
  User? _mockUser;
  bool _shouldFail = false;

  void setMockUser(User user) {
    _mockUser = user;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  TaskEither<String, User> getUser() {
    return TaskEither(() async {
      if (_shouldFail) {
        return left('User not found');
      }

      final user =
          _mockUser ??
          User(
            id: 'mock_user_id',
            verificationLevel: 0,
            referredBy: null,
            allowedSpending: 25000,
            dailySpending: 5000,
            spendingLevel: 1,
            levelProgress: 1,
            valuesToReceive: {
              '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189':
                  15000000000,
              // '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d':
              //     25000,
            },
          );

      return right(user);
    });
  }

  @override
  TaskEither<String, bool> validateReferralCode(String referralCode) {
    return TaskEither(() async {
      if (_shouldFail) {
        return left('Failed to validate referral');
      }
      return right(referralCode.startsWith('VALID'));
    });
  }

  @override
  TaskEither<String, Unit> addReferral(String referralCode) {
    return TaskEither(() async {
      if (_shouldFail) {
        return left('Failed to add referral');
      }
      return right(unit);
    });
  }
}
