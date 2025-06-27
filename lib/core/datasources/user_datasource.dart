abstract class UserDataSource {
  Future<Map<String, dynamic>> fetch(String userId, String jwt);
  Future<void> updateReferral(String userId, String referralCode, String jwt);
}
