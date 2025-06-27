class User {
  final String id;
  final int allowedSpending;
  final int dailySpending;
  final bool verified;
  final String? referredBy;

  User({
    required this.id,
    required this.allowedSpending,
    required this.dailySpending,
    required this.verified,
    this.referredBy,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      allowedSpending: json['allowed_spending'],
      dailySpending: json['daily_spending'],
      verified: json['verified'],
      referredBy: json['referred_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'allowed_spending': allowedSpending,
      'daily_spending': dailySpending,
      'verified': verified,
      'referred_by': referredBy,
    };
  }
}
