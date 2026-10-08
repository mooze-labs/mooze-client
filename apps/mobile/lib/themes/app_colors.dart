import 'package:flutter/material.dart';
import 'generated/app_palette.dart';

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
    primary: AppPaletteDark.primary,
    onPrimary: AppPaletteDark.onPrimary,
    primaryContainer: AppPaletteDark.primaryContainer,
    onPrimaryContainer: AppPaletteDark.onPrimaryContainer,
    // Secondary
    secondary: AppPaletteDark.secondary,
    onSecondary: AppPaletteDark.onSecondary,
    secondaryContainer: AppPaletteDark.secondaryContainer,
    onSecondaryContainer: AppPaletteDark.onSecondaryContainer,
    // Tertiary (positive/success)
    tertiary: AppPaletteDark.tertiary,
    onTertiary: AppPaletteDark.onTertiary,
    tertiaryContainer: AppPaletteDark.tertiaryContainer,
    onTertiaryContainer: AppPaletteDark.onTertiaryContainer,
    // Error (negative)
    error: AppPaletteDark.error,
    onError: AppPaletteDark.onError,
    errorContainer: AppPaletteDark.errorContainer,
    onErrorContainer: AppPaletteDark.onErrorContainer,
    // Surface
    surface: AppPaletteDark.surface,
    onSurface: AppPaletteDark.onSurface,
    surfaceTint: AppPaletteDark.surfaceTint,
    surfaceDim: AppPaletteDark.surfaceDim,
    surfaceBright: AppPaletteDark.surfaceBright,
    surfaceContainerLowest: AppPaletteDark.surfaceContainerLowest,
    surfaceContainerLow: AppPaletteDark.surfaceContainerLow,
    surfaceContainer: AppPaletteDark.surfaceContainer,
    surfaceContainerHigh: AppPaletteDark.surfaceContainerHigh,
    surfaceContainerHighest: AppPaletteDark.surfaceContainerHighest,
    // Outline
    outline: AppPaletteDark.outline,
    outlineVariant: AppPaletteDark.outlineVariant,
    // Inverse
    inverseSurface: AppPaletteDark.inverseSurface,
    onInverseSurface: AppPaletteDark.onInverseSurface,
    inversePrimary: AppPaletteDark.inversePrimary,
    // Overlay
    scrim: AppPaletteDark.scrim,
    shadow: AppPaletteDark.shadow,
  );

  /// Material 3 [ColorScheme] for the light theme — used by [AppTheme.lightTheme].
  static const ColorScheme lightColorScheme = ColorScheme.light(
    brightness: Brightness.light,

    // Primary (Accent)
    primary: AppPaletteLight.primary,
    onPrimary: AppPaletteLight.onPrimary,
    primaryContainer: AppPaletteLight.primaryContainer,
    onPrimaryContainer: AppPaletteLight.onPrimaryContainer,

    // Secondary
    secondary: AppPaletteLight.secondary,
    onSecondary: AppPaletteLight.onSecondary,
    secondaryContainer: AppPaletteLight.secondaryContainer,
    onSecondaryContainer: AppPaletteLight.onSecondaryContainer,

    // Tertiary (Success)
    tertiary: AppPaletteLight.tertiary,
    onTertiary: AppPaletteLight.onTertiary,
    tertiaryContainer: AppPaletteLight.tertiaryContainer,
    onTertiaryContainer: AppPaletteLight.onTertiaryContainer,

    // Error
    error: AppPaletteLight.error,
    onError: AppPaletteLight.onError,
    errorContainer: AppPaletteLight.errorContainer,
    onErrorContainer: AppPaletteLight.onErrorContainer,

    // Surface / Background
    surface: AppPaletteLight.surface,
    onSurface: AppPaletteLight.onSurface,
    surfaceTint: AppPaletteLight.surfaceTint,

    surfaceDim: AppPaletteLight.surfaceDim,
    surfaceBright: AppPaletteLight.surfaceBright,

    surfaceContainerLowest: AppPaletteLight.surfaceContainerLowest,
    surfaceContainerLow: AppPaletteLight.surfaceContainerLow,
    surfaceContainer: AppPaletteLight.surfaceContainer,
    surfaceContainerHigh: AppPaletteLight.surfaceContainerHigh,
    surfaceContainerHighest: AppPaletteLight.surfaceContainerHighest,

    // Outline / Borders
    outline: AppPaletteLight.outline,
    outlineVariant: AppPaletteLight.outlineVariant,

    // Inverse
    inverseSurface: AppPaletteLight.inverseSurface,
    onInverseSurface: AppPaletteLight.onInverseSurface,
    inversePrimary: AppPaletteLight.inversePrimary,

    // Overlay
    scrim: AppPaletteLight.scrim,
    shadow: AppPaletteLight.shadow,
  );
}
