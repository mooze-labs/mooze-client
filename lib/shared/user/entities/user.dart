class User {
  final String pubKey;
  final int verificationLevel;
  final String? referredBy;

  User({
    required this.pubKey,
    required this.verificationLevel,
    this.referredBy,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      pubKey: json['public_key'] as String,
      verificationLevel: json['verification_level'] as int,
      referredBy: json['referred_by'] as String?,
    );
  }
}
