class WalletLevelLimitsEntity {
  final int maxLimit;
  final int minLimit;

  const WalletLevelLimitsEntity({
    required this.maxLimit,
    required this.minLimit,
  });

  double get maxLimitInReais => maxLimit / 100.0;
  double get minLimitInReais => minLimit / 100.0;
}
