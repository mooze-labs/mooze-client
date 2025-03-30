class User {
  String id;
  int dailySpending;
  bool isFirstTransaction;
  bool verified;

  User({
    required this.id,
    required this.dailySpending,
    required this.isFirstTransaction,
    required this.verified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      dailySpending: json['daily_spending'],
      isFirstTransaction: json['is_first_transaction'],
      verified: json['verified'],
    );
  }
}
