import 'package:flutter/material.dart';

/// Theme extension for semantic colors not covered by Material's ColorScheme.
///
/// Access via `Theme.of(context).extension<AppExtraColors>()`.
@immutable
class AppExtraColors extends ThemeExtension<AppExtraColors> {
  /// Base warning color (backgrounds, borders with opacity).
  final Color warning;

  /// Foreground color for warning text and icons.
  final Color onWarning;

  const AppExtraColors({
    required this.warning,
    required this.onWarning,
  });

  /// Default dark theme values.
  static const dark = AppExtraColors(
    warning: Color(0xFFFB8C00),
    onWarning: Color(0xFFFFB74D),
  );

  @override
  AppExtraColors copyWith({Color? warning, Color? onWarning}) {
    return AppExtraColors(
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
    );
  }

  @override
  AppExtraColors lerp(AppExtraColors? other, double t) {
    if (other is! AppExtraColors) return this;
    return AppExtraColors(
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }
}
