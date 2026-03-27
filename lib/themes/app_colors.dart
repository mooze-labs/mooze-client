import 'package:flutter/material.dart';

/// Owns the app's Material 3 [ColorScheme] definitions.
///
/// This class contains **only** the two scheme constants — one for dark mode
/// and one for light mode. All individual color values that used to live here
/// as static constants have been moved into the theme system:
///
/// - Standard roles → [ColorScheme] fields on [darkColorScheme] / [lightColorScheme]
/// - Custom roles   → [AppExtraColors] (dark/light instances in `app_extra_colors.dart`)
///
/// **In widgets, never import this file directly.**
/// Access colors via `context.colors`, `context.colorScheme`, or
/// `context.appColors` (all from `theme_context_x.dart`).
class AppColors {
  AppColors._();

  /// Material 3 [ColorScheme] for the dark theme — used by [AppTheme.darkTheme].
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    // Primary
    primary: Color(0xFFEA1E63),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF4A0E2A),
    onPrimaryContainer: Color(0xFFFFD9E4),
    // Secondary
    secondary: Color(0xFF212121),
    onSecondary: Colors.white60,
    secondaryContainer: Color(0xFF383838),
    onSecondaryContainer: Color(0xFFE6E1E5),
    // Tertiary (positive/success)
    tertiary: Color(0xFF32B153),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF0F3A1C),
    onTertiaryContainer: Color(0xFFB7F397),
    // Error (negative)
    error: Color(0xFFD73131),
    onError: Colors.white,
    errorContainer: Color(0xFF410E0B),
    onErrorContainer: Color(0xFFF2B8B5),
    // Surface
    surface: Color(0xFF141722),
    onSurface: Colors.white,
    surfaceTint: Color(0xFFEA1E63),
    surfaceDim: Color(0xFF000000),
    surfaceBright: Color(0xFF1F1F1F),
    surfaceContainerLowest: Color(0xFF0A0A0A),
    surfaceContainerLow: Color(0xFF111111),
    surfaceContainer: Color(0xFF141722),
    surfaceContainerHigh: Color(0xFF1C1C1C),
    surfaceContainerHighest: Color(0xFF26252A),
    // Outline
    outline: Color(0xFF2D2E2A),
    outlineVariant: Color(0xFF7C7C7C),
    // Inverse
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF9F4052),
    // Overlay
    scrim: Color(0xFF000000),
    shadow: Color(0xFF000000),
  );

  /// Material 3 [ColorScheme] for the light theme — used by [AppTheme.lightTheme].
  static const ColorScheme lightColorScheme = ColorScheme.light(
    brightness: Brightness.light,
    // Primary
    primary: Color(0xFFEA1E63),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFD9E4),
    onPrimaryContainer: Color(0xFF3E0020),
    // Secondary
    secondary: Color(0xFF5A5A5A),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE8E8E8),
    onSecondaryContainer: Color(0xFF1A1A1A),
    // Tertiary (positive/success)
    tertiary: Color(0xFF1A7A36),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFB7F0C8),
    onTertiaryContainer: Color(0xFF002110),
    // Error
    error: Color(0xFFD73131),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    // Surface
    surface: Color(0xFFF5F5F5),
    onSurface: Color(0xFF1A1A1A),
    surfaceTint: Color(0xFFEA1E63),
    surfaceDim: Color(0xFFE8E8E8),
    surfaceBright: Colors.white,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF5F5F5),
    surfaceContainer: Color(0xFFEEEEEE),
    surfaceContainerHigh: Color(0xFFE8E8E8),
    surfaceContainerHighest: Color(0xFFE0E0E0),
    // Outline
    outline: Color(0xFFBDBDBD),
    outlineVariant: Color(0xFFD4D4D4),
    // Inverse
    inverseSurface: Color(0xFF303033),
    onInverseSurface: Color(0xFFF2EFF4),
    inversePrimary: Color(0xFFFFB0C8),
    // Overlay
    scrim: Colors.black,
    shadow: Colors.black,
  );
}
