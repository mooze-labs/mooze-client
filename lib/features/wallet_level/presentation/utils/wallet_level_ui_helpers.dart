import 'package:flutter/material.dart';

/// Centralizes UI-related wallet level mappings (colors, icons, names).
/// Keeps Flutter dependencies out of the domain layer while avoiding
/// duplicated switch statements across screens.
class WalletLevelUiHelpers {
  WalletLevelUiHelpers._();

  static Color getLevelColor(int level) {
    switch (level) {
      case 0:
        return const Color(0xFF8B7355);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFFFD700);
      case 3:
        return const Color(0xFF4169E1);
      default:
        return Colors.grey;
    }
  }

  static IconData getLevelIcon(int level) {
    switch (level) {
      case 0:
        return Icons.military_tech;
      case 1:
        return Icons.workspace_premium;
      case 2:
        return Icons.emoji_events;
      case 3:
        return Icons.diamond;
      default:
        return Icons.military_tech;
    }
  }

  static String getLevelName(int level) {
    switch (level) {
      case 0:
        return 'Bronze';
      case 1:
        return 'Prata';
      case 2:
        return 'Ouro';
      case 3:
        return 'Diamante';
      default:
        return 'Bronze';
    }
  }
}
