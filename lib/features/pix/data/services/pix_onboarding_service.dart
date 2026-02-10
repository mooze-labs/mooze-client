import 'package:shared_preferences/shared_preferences.dart';

class PixOnboardingService {
  static const String _pixMainFirstTimeDialogKey =
      'pix_main_first_time_dialog_shown';
  static const String _pixMerchantFirstTimeDialogKey =
      'pix_merchant_first_time_dialog_shown';

  final SharedPreferences _prefs;

  PixOnboardingService(this._prefs);

  /// Checks if the user has already seen the main PIX first-time dialog
  bool hasSeenFirstTimeDialog() {
    return _prefs.getBool(_pixMainFirstTimeDialogKey) ?? false;
  }

  /// Marks that the user has already seen and accepted the main PIX first-time dialog
  Future<void> markFirstTimeDialogAsSeen() async {
    await _prefs.setBool(_pixMainFirstTimeDialogKey, true);
  }

  /// Resets the main PIX dialog state (useful for tests or if it needs to be shown again)
  Future<void> resetFirstTimeDialog() async {
    await _prefs.remove(_pixMainFirstTimeDialogKey);
  }

  /// Checks if the user has already seen the Merchant PIX first-time dialog
  bool hasSeenMerchantFirstTimeDialog() {
    return _prefs.getBool(_pixMerchantFirstTimeDialogKey) ?? false;
  }

  /// Marks that the user has already seen and accepted the Merchant PIX first-time dialog
  Future<void> markMerchantFirstTimeDialogAsSeen() async {
    await _prefs.setBool(_pixMerchantFirstTimeDialogKey, true);
  }

  /// Resets the Merchant dialog state (useful for tests or if it needs to be shown again)
  Future<void> resetMerchantFirstTimeDialog() async {
    await _prefs.remove(_pixMerchantFirstTimeDialogKey);
  }

  // Methods prepared for future API integration

  /// Syncs the onboarding state with the backend
  /// TODO: Implement when the backend endpoint is available
  Future<void> syncWithBackend() async {
    // Future implementation:
    // - Fetch state from the server
    // - Update local state if needed
    // - Send local state if needed
  }

  /// Checks if the user has accepted the terms on the server
  /// TODO: Implement when the backend endpoint is available
  Future<bool> hasAcceptedTermsOnBackend() async {
    // Future implementation:
    // - Make request to the backend
    // - Return whether the user has already accepted
    return hasSeenFirstTimeDialog(); // For now, uses local state
  }

  /// Sends terms acceptance to the backend
  /// TODO: Implement when the backend endpoint is available
  Future<void> submitTermsAcceptance() async {
    // Future implementation:
    // - Send acceptance timestamp
    // - Accepted terms version
    // - Device info if needed
    await markFirstTimeDialogAsSeen();
  }
}
