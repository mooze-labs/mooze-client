import 'package:flutter/foundation.dart';

class WalletSyncConfig {
  static const bool isHotReloadDetectionEnabled = kDebugMode;

  static const bool isVerboseLoggingEnabled = kDebugMode;

  static const bool isAutoResetEnabled = kDebugMode;

  static const bool isDebugButtonsEnabled = kDebugMode;

  static Duration get retryInterval =>
      kReleaseMode ? const Duration(seconds: 5) : const Duration(seconds: 2);

  static int get maxRetries => kReleaseMode ? 5 : 3;

  static Duration get datasourceTimeout =>
      kReleaseMode
          ? const Duration(seconds: 10)
          : const Duration(milliseconds: 500);

  static const bool showTechnicalErrorDetails = kDebugMode;

  static const bool isSyncAnalyticsEnabled = kReleaseMode;
}

class WalletSyncLogger {
  static void debug(String message) {
    if (WalletSyncConfig.isVerboseLoggingEnabled) {
      debugPrint(message);
    }
  }

  static void info(String message) {
    debugPrint(message);
  }

  static void error(String message) {
    debugPrint('[ERROR] $message');

    if (WalletSyncConfig.isSyncAnalyticsEnabled) {
      _sendToAnalytics(message);
    }
  }

  static void _sendToAnalytics(String message) {
    // TODO: Integrate with Analytics service
  }
}
