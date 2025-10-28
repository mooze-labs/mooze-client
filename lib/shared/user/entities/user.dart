class User {
  final String id;
  final int verificationLevel;
  final String? referredBy;
  final double allowedSpending;
  final double dailySpending;
  final int spendingLevel;
  final double levelProgress;

  User({
    required this.id,
    required this.verificationLevel,
    this.referredBy,
    required this.allowedSpending,
    required this.dailySpending,
    required this.spendingLevel,
    required this.levelProgress,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return User(
      id: data['user_id'] as String,
      verificationLevel: data['verification_level'] as int,
      referredBy: data['referred_by'] as String?,
      allowedSpending: (data['allowed_spending'] as num).toDouble(),
      dailySpending: (data['daily_spending'] as num).toDouble(),
      spendingLevel: data['spending_level'] as int,
      levelProgress: (data['level_progress'] as num).toDouble(),
    );
  }
}
