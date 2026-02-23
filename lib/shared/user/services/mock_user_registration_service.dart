import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import 'user_registration_service.dart';

class MockUserRegistrationService implements UserRegistrationService {
  User? _mockUser;
  bool _shouldFail = false;

  void setMockUser(User user) {
    _mockUser = user;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  TaskEither<String, User> createNewUser(
    String publicKey,
    String? referralCode,
  ) {
    return TaskEither(() async {
      if (_shouldFail) {
        return left('Failed to create new user');
      }

      final user =
          _mockUser ??
          User(
            id: publicKey,
            verificationLevel: 0,
            referredBy: referralCode,
            allowedSpending: 2900,
            dailySpending: 5000,
            spendingLevel: 1,
            levelProgress: 1,
            valuesToReceive: {
              '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189':
                  15000000000,
              '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d':
                  25000,
            },
          );

      return right(user);
    });
  }
}
