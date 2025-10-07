class AuthChallenge {
  final String challengeId;
  final String message;

  AuthChallenge({
    required this.challengeId,
    required this.message,
  });

  factory AuthChallenge.fromJson(Map<String, dynamic> json) {
    return AuthChallenge(
      challengeId: json['challenge_id'],
      message: json['message'],
    );
  }
}
