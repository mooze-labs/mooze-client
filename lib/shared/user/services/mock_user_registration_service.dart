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
      
      final user = _mockUser ?? User(
        pubKey: publicKey,
        verificationLevel: 0,
        referredBy: referralCode,
      );
      
      return right(user);
    });
  }
}