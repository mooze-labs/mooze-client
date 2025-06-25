class User {
  String id;
  String identityPubKey;
  int dailySpending;
  int allowedSpending;
  int verified;
  String? referredBy;

  User({
    required this.id,
    required this.identityPubKey,
    required this.dailySpending,
    required this.allowedSpending,
    required this.verified,
    this.referredBy,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      identityPubKey: json['identity_pub_key'],
      dailySpending: json['daily_spending'],
      allowedSpending: json['allowed_spending'],
      referredBy: json['referred_by'],
      verified: json['verified'],
    );
  }
}
