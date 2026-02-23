class User {
  final String id;
  final int verificationLevel;
  final String? referredBy;
  final double allowedSpending;
  final double dailySpending;
  final int spendingLevel;
  final double levelProgress;
  final Map<String, int> valuesToReceive;

  User({
    required this.id,
    required this.verificationLevel,
    this.referredBy,
    required this.allowedSpending,
    required this.dailySpending,
    required this.spendingLevel,
    required this.levelProgress,
    required this.valuesToReceive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    final Map<String, int> valuesToReceive = {};
    if (data['to_receive'] != null && data['to_receive'] is Map) {
      final toReceiveMap = data['to_receive'] as Map<String, dynamic>;
      toReceiveMap.forEach((key, value) {
        if (value is int) {
          valuesToReceive[key] = value;
        } else if (value is num) {
          valuesToReceive[key] = value.toInt();
        }
      });
    }
    
    return User(
      id: data['user_id'] as String,
      verificationLevel: data['verification_level'] as int,
      referredBy: data['referred_by'] as String?,
      allowedSpending: (data['allowed_spending'] as num).toDouble(),
      dailySpending: (data['daily_spending'] as num).toDouble(),
      spendingLevel: data['spending_level'] as int,
      levelProgress: (data['level_progress'] as num).toDouble(),
      valuesToReceive: valuesToReceive,
    );
  }
}
