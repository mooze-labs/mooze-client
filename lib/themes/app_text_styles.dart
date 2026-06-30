import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/extensions.dart';
import 'app_extra_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Legacy static styles ──────────────────────────────────────────────────
  // These are dark-theme-only constants kept for backward compatibility.
  // Prefer Theme.of(context).textTheme.titleLarge / titleMedium / bodyLarge
  // when context is available, as those are fully theme-aware.

  @Deprecated('Use Theme.of(context).textTheme.titleLarge instead.')
  static const TextStyle title = TextStyle(
    color:
        Colors
            .white, // dark-theme fallback — use textTheme.titleLarge for theme-aware
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  @Deprecated('Use Theme.of(context).textTheme.bodyMedium instead.')
  static const TextStyle subtitle = TextStyle(
    color:
        Colors
            .white60, // dark-theme fallback — use textTheme.bodyMedium for theme-aware
    fontSize: 14,
  );

  @Deprecated('Use Theme.of(context).textTheme.bodyLarge instead.')
  static const TextStyle value = TextStyle(
    color:
        Colors
            .white, // dark-theme fallback — use textTheme.bodyLarge for theme-aware
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const double buttonTextSize = 20.0;

  // ── Theme-aware builders ──────────────────────────────────────────────────

  /// Builds a fully theme-aware [TextTheme] using tokens from [colorScheme]
  /// and [extraColors].
  ///
  /// Called once during [ThemeData] construction in [AppTheme].
  static TextTheme buildResponsiveTextTheme(
    BuildContext context,
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) {
    return TextTheme(
      // Display styles — primary content, high visual weight
      displayLarge: TextStyle(
        fontSize: context.responsiveFont(40),
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
        fontFamily: "Inter",
      ),
      displayMedium: TextStyle(
        fontSize: context.responsiveFont(36),
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        fontFamily: "Inter",
      ),
      displaySmall: TextStyle(
        fontSize: context.responsiveFont(32),
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        height: 1.2,
        fontFamily: "Inter",
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: context.responsiveFont(32),
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: "Inter",
      ),
      headlineMedium: TextStyle(
        fontSize: context.responsiveFont(28),
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: "Inter",
      ),
      headlineSmall: TextStyle(
        fontSize: context.responsiveFont(24),
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        fontFamily: "Inter",
      ),

      // Title styles — section headings and list-item primary text
      titleLarge: TextStyle(
        fontSize: context.responsiveFont(22),
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        fontFamily: "Inter",
      ),
      titleMedium: TextStyle(
        fontSize: context.responsiveFont(16),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: extraColors.textSecondary,
        fontFamily: "Inter",
      ),
      titleSmall: TextStyle(
        fontSize: context.responsiveFont(14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: extraColors.textSecondary,
        fontFamily: "Inter",
      ),

      // Label styles — buttons, chips, tabs
      labelLarge: TextStyle(
        fontSize: context.responsiveFont(14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        fontFamily: "Inter",
      ),
      labelMedium: TextStyle(
        fontSize: context.responsiveFont(12),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: extraColors.textSecondary,
        fontFamily: "Inter",
      ),
      labelSmall: TextStyle(
        fontSize: context.responsiveFont(11),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: extraColors.textTertiary,
        fontFamily: "Inter",
      ),

      // Body styles — paragraph content
      bodyLarge: TextStyle(
        fontSize: context.responsiveFont(16),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        fontFamily: "Inter",
      ),
      bodyMedium: TextStyle(
        fontSize: context.responsiveFont(15),
        color: extraColors.textSecondary,
        fontFamily: "Inter",
      ),
      bodySmall: TextStyle(
        fontSize: context.responsiveFont(12),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: extraColors.textTertiary,
        fontFamily: "Inter",
      ),
    );
  }

  /// Theme-aware [TextStyle] for [AppBar] titles.
  static TextStyle appBarTitle(BuildContext context, ColorScheme colorScheme) =>
      TextStyle(
        fontSize: context.responsiveFont(20),
        fontFamily: "roboto",
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      );

  /// Theme-aware [TextStyle] for primary action buttons.
  static TextStyle buttonText(BuildContext context, ColorScheme colorScheme) =>
      TextStyle(
        fontSize: context.responsiveFont(buttonTextSize),
        fontWeight: FontWeight.w500,
        fontFamily: "Inter",
        color: colorScheme.onPrimary,
        letterSpacing: 0.0,
      );
}
