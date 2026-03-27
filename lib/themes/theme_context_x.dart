import 'package:flutter/material.dart';
import 'app_colors_proxy.dart';
import 'app_extra_colors.dart';

/// Convenience accessors for the active [ThemeData] on a [BuildContext].
///
/// Eliminates boilerplate in widgets and provides a consistent, concise API
/// for accessing theme tokens without scattering `Theme.of(context)` calls.
///
/// **Usage:**
/// ```dart
/// import 'package:mooze_mobile/themes/theme_context_x.dart';
///
/// // Unified proxy — same property names as the old AppColors static class
/// color: context.colors.primaryColor
/// color: context.colors.backgroundColor
/// color: context.colors.textSecondary
///
/// // Standard Material 3 roles
/// color: context.colorScheme.surfaceDim
/// color: context.colorScheme.primary
///
/// // Custom app tokens (warning, shimmer, PIN surface, etc.)
/// color: context.appColors.shimmerBase
/// color: context.appColors.navBarFabBackground
///
/// // Typography
/// style: context.textTheme.titleLarge
/// ```
///
/// **Migration guide — replacing bare `AppColors` constants:**
/// | Old (dark-only)                          | New (theme-aware)                            |
/// |------------------------------------------|----------------------------------------------|
/// | `AppColors.backgroundColor`              | `context.colors.backgroundColor`             |
/// | `AppColors.backgroundCard`               | `context.colors.backgroundCard`              |
/// | `AppColors.primaryColor`                 | `context.colors.primaryColor`                |
/// | `AppColors.textPrimary`                  | `context.colors.textPrimary`                 |
/// | `AppColors.textSecondary`                | `context.colors.textSecondary`               |
/// | `AppColors.textTertiary`                 | `context.colors.textTertiary`                |
/// | `AppColors.negativeColor`                | `context.colors.negativeColor`               |
/// | `AppColors.positiveColor`                | `context.colors.positiveColor`               |
/// | `AppColors.surfaceColor`                 | `context.colors.surfaceColor`                |
/// | `AppColors.baseColor` (shimmer)          | `context.colors.baseColor`                   |
/// | `AppColors.highlightColor` (shimmer)     | `context.colors.highlightColor`              |
extension AppThemeContextX on BuildContext {
  /// Unified theme-aware proxy with the same property names as the old
  /// `AppColors` static class. Every property resolves from the active theme.
  ///
  /// This is the primary migration target: `AppColors.foo` → `context.colors.foo`.
  AppColorsProxy get colors {
    final cs = Theme.of(this).colorScheme;
    final extra = Theme.of(this).extension<AppExtraColors>()!;
    return AppColorsProxy(cs, extra);
  }

  /// The [ColorScheme] of the nearest enclosing [Theme].
  ///
  /// Covers all standard Material 3 roles (primary, surface, error, etc.).
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// The [AppExtraColors] extension of the nearest enclosing [Theme].
  ///
  /// Covers app-specific roles not present in Material's [ColorScheme]:
  /// shimmer, warning, PIN surface, nav FAB, extended text tiers, etc.
  AppExtraColors get appColors => Theme.of(this).extension<AppExtraColors>()!;

  /// The [TextTheme] of the nearest enclosing [Theme].
  TextTheme get textTheme => Theme.of(this).textTheme;
}
