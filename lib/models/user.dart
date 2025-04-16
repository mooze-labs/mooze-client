class User {
  String id;
  int dailySpending;
  int allowedSpending;
  int verificationLevel;
  String? referredBy;

  User({
    required this.id,
    required this.dailySpending,
    required this.allowedSpending,
    required this.verificationLevel,
    this.referredBy,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      dailySpending: json['daily_spending'],
      allowedSpending: json['allowed_spending'],
      verificationLevel: json['verification_level'],
      referredBy: json['referred_by'],
    );
  }
}
