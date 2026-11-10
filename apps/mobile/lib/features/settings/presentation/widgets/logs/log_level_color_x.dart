import 'package:flutter/material.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Theme-aware visual tokens for a [LogLevel] — signal color and glyph.
///
/// Centralising these keeps the log list, filters, stats, and detail sheet
/// visually consistent: a level always reads as the same color + icon pair
/// across the whole feature. The color is a small signal (a dot or a label),
/// never a fill. Every color comes from the theme. Error and critical share
/// the error color; the label and the glyph tell them apart.
extension LogLevelColorX on LogLevel {
  Color color(BuildContext context) {
    switch (this) {
      case LogLevel.debug:
        return context.colors.textTertiary;
      case LogLevel.info:
        return context.colorScheme.tertiary;
      case LogLevel.warning:
        return context.appColors.warning;
      case LogLevel.error:
      case LogLevel.critical:
        return context.colorScheme.error;
    }
  }

  IconData get icon {
    switch (this) {
      case LogLevel.debug:
        return Icons.bug_report_outlined;
      case LogLevel.info:
        return Icons.info_outline_rounded;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.error:
        return Icons.error_outline_rounded;
      case LogLevel.critical:
        return Icons.dangerous_outlined;
    }
  }
}
