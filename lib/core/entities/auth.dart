class AuthenticationChallengeResponse {
  final String publicKey;
  final String signature;

  AuthenticationChallengeResponse({
    required this.publicKey,
    required this.signature,
  });
}
