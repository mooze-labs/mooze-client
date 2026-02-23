class AuthChallenge {
  final String challengeId;
  final String message;

  AuthChallenge({required this.challengeId, required this.message});

  factory AuthChallenge.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return AuthChallenge(challengeId: data['id'], message: data['message']);
  }
}
