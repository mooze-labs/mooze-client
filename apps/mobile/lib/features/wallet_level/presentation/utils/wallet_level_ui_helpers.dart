import 'package:flutter/material.dart';

/// Centralizes UI-related wallet level mappings (colors, icons). The
/// localized names come from the `levelName` extension on
/// `AppLocalizations`.
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

  /// Returns the color of the medal of the level, its emblem, and its
  /// light on the level change screens: brightened to glow on black in the
  /// dark theme, deepened to show on a light page in the light theme.
  static Color getLevelTint(int level, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (level) {
      case 1:
        return dark ? const Color(0xFFD9DEE5) : const Color(0xFF7F93AD);
      case 2:
        return dark ? const Color(0xFFFFD54A) : const Color(0xFFD6A21E);
      case 3:
        return dark ? const Color(0xFF7B9CFF) : const Color(0xFF3F66E6);
      default:
        return dark ? const Color(0xFFD19A66) : const Color(0xFFB8733A);
    }
  }

  /// Returns the emblem of the level: one, two, or three chevrons for
  /// Bronze, Silver, and Gold, and a cut gem for Diamond.
  static String getLevelEmblem(int level) {
    switch (level) {
      case 1:
        return 'assets/icons/level/silver.svg';
      case 2:
        return 'assets/icons/level/gold.svg';
      case 3:
        return 'assets/icons/level/diamond.svg';
      default:
        return 'assets/icons/level/bronze.svg';
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
}
