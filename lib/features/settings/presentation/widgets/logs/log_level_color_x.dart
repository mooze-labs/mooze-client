import 'package:flutter/material.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

extension LogLevelColorX on LogLevel {
  Color color(BuildContext context) {
    switch (this) {
      case LogLevel.debug:
        return context.colors.textTertiary;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return context.appColors.warning;
      case LogLevel.error:
        return context.colorScheme.error;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
}
