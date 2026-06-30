import 'package:shared_preferences/shared_preferences.dart';

/// Merchant Tutorial Service (Presentation Layer)
///
/// Manages the tutorial state for merchant mode.
/// Tracks whether the user has seen the interactive tutorial
/// that guides them through using merchant mode features.
///
/// Storage: Uses SharedPreferences for persistent storage
/// Key: 'merchant_tutorial_shown' (boolean)
///
/// Usage:
/// - On merchant mode entry: Check if tutorial has been shown
/// - If not shown: Display tutorial, then mark as shown
/// - Reset: Available for testing/debugging (clears tutorial state)
///
/// Note: This is a UI-specific service that doesn't follow Clean Architecture
/// (doesn't use use cases). Consider moving to a ui_services/ folder to make
/// this distinction clearer.
class MerchantTutorialService {
  /// SharedPreferences key for storing tutorial shown state
  static const String _tutorialShownKey = 'merchant_tutorial_shown';

  /// Checks if the tutorial has been shown to the user
  /// Returns: true if tutorial was already shown, false if first time
  Future<bool> isTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialShownKey) ?? false;
  }

  /// Marks the tutorial as shown (call after tutorial completion)
  /// Prevents the tutorial from showing again on subsequent visits
  Future<void> setTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialShownKey, true);
  }

  /// Resets the tutorial state (for testing/debugging)
  /// After calling this, the tutorial will show again on next merchant mode entry
  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialShownKey);
  }
}
