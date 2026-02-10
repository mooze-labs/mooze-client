class CurrentUserWalletEntity {
  final double currentLimit;
  final double maximumPossibleLimit;
  final double minimumLimit;
  final String currentLevel;

  const CurrentUserWalletEntity({
    required this.currentLimit,
    required this.maximumPossibleLimit,
    required this.minimumLimit,
    required this.currentLevel,
  });
}
