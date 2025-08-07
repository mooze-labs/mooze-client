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
      if (_mockUser == null) {
        return left('User not found');
      }
      return right(_mockUser!);
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