import 'package:flutter/material.dart';

/// Defines the visual type of a SnackBar notification.
enum SnackBarType {
  success,
  error,
  warning,
  info,
}

/// Centralized SnackBar helper for consistent UI feedback across the app.

class AppSnackBar {
  AppSnackBar._();

  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _errorDuration = Duration(seconds: 5);

  /// Shows a SnackBar with the given [type] styling.
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_iconFor(type), color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: _colorFor(type),
          behavior: SnackBarBehavior.floating,
          duration: duration ?? _durationFor(type),
          action: action,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
  }

  /// Shows a green success SnackBar.
  static void success(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.success);

  /// Shows a red error SnackBar.
  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.error);

  /// Shows an orange warning SnackBar.
  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.warning);

  /// Shows a blue info SnackBar.
  static void info(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.info);

  static Color _colorFor(SnackBarType type) {
    return switch (type) {
      SnackBarType.success => const Color(0xFF388E3C),
      SnackBarType.error => const Color(0xFFC62828),
      SnackBarType.warning => const Color(0xFFE65100),
      SnackBarType.info => const Color(0xFF1565C0),
    };
  }

  static IconData _iconFor(SnackBarType type) {
    return switch (type) {
      SnackBarType.success => Icons.check_circle_rounded,
      SnackBarType.error => Icons.error_rounded,
      SnackBarType.warning => Icons.warning_rounded,
      SnackBarType.info => Icons.info_rounded,
    };
  }

  static Duration _durationFor(SnackBarType type) {
    return switch (type) {
      SnackBarType.error => _errorDuration,
      _ => _defaultDuration,
    };
  }
}
