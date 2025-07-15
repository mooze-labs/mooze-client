class AuthenticationChallenge {
  final String challengeId;
  final String nonce;
  final String pubkeyFpr;
  final String timestamp;

  AuthenticationChallenge({
    required this.challengeId,
    required this.nonce,
    required this.pubkeyFpr,
    required this.timestamp,
  });

  factory AuthenticationChallenge.fromJson(Map<String, dynamic> json) {
    return AuthenticationChallenge(
      challengeId: json['challenge_id'],
      nonce: json['nonce'],
      pubkeyFpr: json['pubkey_fpr'],
      timestamp: json['timestamp'],
    );
  }
}
