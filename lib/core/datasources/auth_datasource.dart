abstract class AuthDatasource {
  Future<Map<String, dynamic>> requestChallenge(String userId);
  Future<Map<String, dynamic>> verifyChallenge(
    String userId,
    String challenge,
    String signature,
  );
}
