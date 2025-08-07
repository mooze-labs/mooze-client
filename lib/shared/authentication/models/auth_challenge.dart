class AuthChallenge {
  final String challengeId;
  final String nonce;
  final String pubkeyFpr;
  final String timestamp;

  AuthChallenge({
    required this.challengeId,
    required this.nonce,
    required this.pubkeyFpr,
    required this.timestamp,
  });

  factory AuthChallenge.fromJson(Map<String, dynamic> json) {
    return AuthChallenge(
      challengeId: json['challenge_id'],
      nonce: json['nonce'],
      pubkeyFpr: json['pubkey_fpr'],
      timestamp: json['timestamp'],
    );
  }
}
