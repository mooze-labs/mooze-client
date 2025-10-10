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
}

class UserLevels {
  static const List<UserLevel> levels = [
    UserLevel(
      order: 1,
      name: 'Bronze',
      description: 'Nível inicial para novos usuários',
      icon: Icons.workspace_premium,
      color: Color(0xFFCD7F32),
      minAmount: 0,
      maxAmount: 1000,
    ),
    UserLevel(
      order: 2,
      name: 'Prata',
      description: 'Usuários com movimentação regular',
      icon: Icons.workspace_premium,
      color: Color(0xFFC0C0C0),
      minAmount: 1001,
      maxAmount: 5000,
    ),
    UserLevel(
      order: 3,
      name: 'Ouro',
      description: 'Usuários com alta movimentação',
      icon: Icons.workspace_premium,
      color: Color(0xFFFFD700),
      minAmount: 5001,
      maxAmount: 20000,
    ),
    UserLevel(
      order: 4,
      name: 'Platina',
      description: 'Usuários premium com benefícios especiais',
      icon: Icons.diamond,
      color: Color(0xFFE5E4E2),
      minAmount: 20001,
      maxAmount: 50000,
    ),
    UserLevel(
      order: 5,
      name: 'Diamante',
      description: 'Nível máximo com todos os benefícios',
      icon: Icons.diamond,
      color: Color(0xFFB9F2FF),
      minAmount: 50001,
      maxAmount: double.infinity,
    ),
  ];

  /// Get level by its order (1-5)
  static UserLevel? getLevelByOrder(int order) {
    if (order < 1 || order > levels.length) return null;
    return levels.firstWhere((level) => level.order == order);
  }

  /// Get next level for progression
  static UserLevel? getNextLevel(int currentOrder) {
    if (currentOrder >= levels.length) return null;
    return levels.firstWhere((level) => level.order == currentOrder + 1);
  }

  /// Get level by amount
  static UserLevel getLevelByAmount(double amount) {
    for (final level in levels) {
      if (amount >= level.minAmount && amount <= level.maxAmount) {
        return level;
      }
    }
    return levels.last;
  }

  static double calculateProgress(double currentAmount, int currentOrder) {
    final level = getLevelByOrder(currentOrder);
    if (level == null) return 0.0;

    final range = level.maxAmount - level.minAmount;
    if (range == double.infinity) return 1.0; // Max level

    final progress = (currentAmount - level.minAmount) / range;
    return progress.clamp(0.0, 1.0);
  }
}
