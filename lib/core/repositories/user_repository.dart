import '../entities/user.dart';

abstract class UserRepository {
  Future<User> getUser(String userId, String authToken);
  Future<void> updateReferral(
    String userId,
    String referralCode,
    String authToken,
  );
}
