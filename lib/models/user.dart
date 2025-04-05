class User {
  String id;
  int dailySpending;
  int allowedSpending;
  bool verified;

  User({
    required this.id,
    required this.dailySpending,
    required this.allowedSpending,
    required this.verified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      dailySpending: json['daily_spending'],
      allowedSpending: json['allowed_spending'],
      verified: json['verified'],
    );
  }
}
