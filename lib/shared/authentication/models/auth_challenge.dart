class AuthChallenge {
  final String challengeId;
  final String nonce;
  final String pubkeyFpr;
  final String timestamp;
  final String message;

  AuthChallenge({
    required this.challengeId,
    required this.nonce,
    required this.pubkeyFpr,
    required this.timestamp,
    required this.message,
  });

  factory AuthChallenge.fromJson(Map<String, dynamic> json) {
    return AuthChallenge(
      challengeId: json['challenge_id'],
      nonce: json['nonce'],
      pubkeyFpr: json['pubkey_fpr'],
      timestamp: json['timestamp'],
      message: json['message'],
    );
  }
}
