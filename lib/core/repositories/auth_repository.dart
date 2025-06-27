abstract class AuthRepository {
  Future<String> requestChallenge(String publicKey);
  Future<String> verifyChallenge(String signedChallenge);
}
