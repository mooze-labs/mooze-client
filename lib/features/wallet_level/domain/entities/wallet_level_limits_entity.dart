class WalletLevelLimitsEntity {
  final int maxLimit;
  final int minLimit;

  const WalletLevelLimitsEntity({
    required this.maxLimit,
    required this.minLimit,
  });

  double get maxLimitInReais => maxLimit / 100.0;
  double get minLimitInReais => minLimit / 100.0;

  @override
  String toString() {
    return 'WalletLevelLimitsEntity(maxLimit: $maxLimit, minLimit: $minLimit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletLevelLimitsEntity &&
        other.maxLimit == maxLimit &&
        other.minLimit == minLimit;
  }

  @override
  int get hashCode => maxLimit.hashCode ^ minLimit.hashCode;
}
