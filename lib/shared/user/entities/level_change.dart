class LevelChange {
  final int oldLevel;
  final int newLevel;
  final LevelChangeType type;

  LevelChange({required this.oldLevel, required this.newLevel})
    : type =
          newLevel > oldLevel
              ? LevelChangeType.upgrade
              : LevelChangeType.downgrade;

  bool get isUpgrade => type == LevelChangeType.upgrade;
  bool get isDowngrade => type == LevelChangeType.downgrade;

  int get levelDifference => (newLevel - oldLevel).abs();
}

enum LevelChangeType { upgrade, downgrade }
