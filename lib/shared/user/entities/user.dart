class User {
  final String id;
  final String verificationLevel;
  final String? referredBy;

  User({required this.id, required this.verificationLevel, this.referredBy});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      verificationLevel: json['verification_level'] as String,
      referredBy: json['referred_by'] as String?,
    );
  }
}
