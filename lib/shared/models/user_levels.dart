import 'package:flutter/material.dart';

class UserLevel {
  final int order;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final double minAmount;
  final double maxAmount;

  const UserLevel({
    required this.order,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.minAmount,
    required this.maxAmount,
  });

  factory UserLevel.fromApiData({
    required int order,
    required String name,
    required double minLimit,
    required double maxLimit,
  }) {
    String description;
    IconData icon;
    Color color;

    switch (name.toLowerCase()) {
      case 'bronze':
        description =
            'Comece movimentando pequenos valores e desbloqueie os primeiros benefícios.';
        icon = Icons.workspace_premium;
        color = const Color(0xFFCD7F32);
        break;
      case 'silver':
        description =
            'Quanto mais você gasta, mais sobe de nível. Alcance o nível Prata.';
        icon = Icons.workspace_premium;
        color = const Color(0xFFC0C0C0);
        break;
      case 'gold':
        description =
            'Nível Gold com limites aumentados para movimentações maiores.';
        icon = Icons.workspace_premium;
        color = const Color(0xFFFFD700);
        break;
      case 'diamond':
        description =
            'Nível máximo com os maiores limites e benefícios exclusivos.';
        icon = Icons.diamond;
        color = const Color(0xFFB9F2FF);
        break;
      default:
        description = 'Nível de usuário';
        icon = Icons.workspace_premium;
        color = const Color(0xFFCD7F32);
    }

    return UserLevel(
      order: order,
      name: name,
      description: description,
      icon: icon,
      color: color,
      minAmount: minLimit,
      maxAmount: maxLimit,
    );
  }
}

class UserLevels {
  static const List<UserLevel> _defaultLevels = [
    UserLevel(
      order: 0,
      name: 'Bronze',
      description:
          'Comece movimentando pequenos valores e desbloqueie os primeiros benefícios.',
      icon: Icons.workspace_premium,
      color: Color(0xFFCD7F32),
      minAmount: 20,
      maxAmount: 250,
    ),
    UserLevel(
      order: 1,
      name: 'Silver',
      description:
          'Quanto mais você gasta, mais sobe de nível. Alcance o nível Prata.',
      icon: Icons.workspace_premium,
      color: Color(0xFFC0C0C0),
      minAmount: 20,
      maxAmount: 500,
    ),
    UserLevel(
      order: 2,
      name: 'Gold',
      description:
          'Nível Gold com limites aumentados para movimentações maiores.',
      icon: Icons.workspace_premium,
      color: Color(0xFFFFD700),
      minAmount: 20,
      maxAmount: 1000,
    ),
    UserLevel(
      order: 3,
      name: 'Diamond',
      description:
          'Nível máximo com os maiores limites e benefícios exclusivos.',
      icon: Icons.diamond,
      color: Color(0xFFB9F2FF),
      minAmount: 20,
      maxAmount: 30000,
    ),
  ];

  static List<UserLevel> get levels => _defaultLevels;

  static UserLevel? getLevelByOrder(int order) {
    if (order < 0 || order >= _defaultLevels.length) return null;
    return _defaultLevels.firstWhere((level) => level.order == order);
  }

  static UserLevel? getNextLevel(int currentOrder) {
    if (currentOrder >= _defaultLevels.length - 1) return null;
    return _defaultLevels.firstWhere(
      (level) => level.order == currentOrder + 1,
    );
  }

  static UserLevel getLevelByAmount(double amount) {
    for (final level in _defaultLevels) {
      if (amount >= level.minAmount && amount <= level.maxAmount) {
        return level;
      }
    }
    return _defaultLevels.last;
  }

  static double calculateProgress({
    required double currentAmount,
    required int currentLevel,
    required double maxLevelLimit,
    required double minLevelLimit,
  }) {
    final range = maxLevelLimit - minLevelLimit;
    if (range <= 0) return 0.0;

    final progress = (currentAmount - minLevelLimit) / range;
    return progress.clamp(0.0, 1.0);
  }

  @Deprecated('Use calculateProgress com parâmetros nomeados da API')
  static double calculateProgressLegacy(
    double currentAmount,
    int currentOrder,
  ) {
    final level = getLevelByOrder(currentOrder);
    if (level == null) return 0.0;

    final range = level.maxAmount - level.minAmount;
    if (range == double.infinity) return 1.0;

    final progress = (currentAmount - level.minAmount) / range;
    return progress.clamp(0.0, 1.0);
  }
}
