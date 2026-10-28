import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/extensions.dart';
import 'app_extra_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  /// The typeface of the app. `pubspec.yaml` registers its files.
  static const String fontFamily = 'Geist';

  // ── Legacy static styles ──────────────────────────────────────────────────
  // These are dark-theme-only constants kept for backward compatibility.
  // Prefer Theme.of(context).textTheme.titleLarge / titleMedium / bodyLarge
  // when context is available, as those are fully theme-aware.

  @Deprecated('Use Theme.of(context).textTheme.titleLarge instead.')
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    color:
        Colors
            .white, // dark-theme fallback — use textTheme.titleLarge for theme-aware
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  @Deprecated('Use Theme.of(context).textTheme.bodyMedium instead.')
  static const TextStyle subtitle = TextStyle(
    fontFamily: fontFamily,
    color:
        Colors
            .white60, // dark-theme fallback — use textTheme.bodyMedium for theme-aware
    fontSize: 14,
  );

  @Deprecated('Use Theme.of(context).textTheme.bodyLarge instead.')
  static const TextStyle value = TextStyle(
    fontFamily: fontFamily,
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
        fontFamily: fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: context.responsiveFont(36),
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: context.responsiveFont(32),
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        height: 1.2,
        fontFamily: fontFamily,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: context.responsiveFont(32),
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: context.responsiveFont(28),
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: context.responsiveFont(24),
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),

      // Title styles — section headings and list-item primary text
      titleLarge: TextStyle(
        fontSize: context.responsiveFont(22),
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: context.responsiveFont(16),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: extraColors.textSecondary,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: context.responsiveFont(14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: extraColors.textSecondary,
        fontFamily: fontFamily,
      ),

      // Label styles — buttons, chips, tabs
      labelLarge: TextStyle(
        fontSize: context.responsiveFont(14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: context.responsiveFont(12),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: extraColors.textSecondary,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: context.responsiveFont(11),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: extraColors.textTertiary,
        fontFamily: fontFamily,
      ),

      // Body styles — paragraph content
      bodyLarge: TextStyle(
        fontSize: context.responsiveFont(16),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: context.responsiveFont(15),
        color: extraColors.textSecondary,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: context.responsiveFont(12),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: extraColors.textTertiary,
        fontFamily: fontFamily,
      ),
    );
  }

  /// Cupertino theme with the app typeface.
  ///
  /// Cupertino widgets, for example [CupertinoDatePicker], do not read the
  /// Material text theme. Without this theme they use the system font. Only
  /// the font family changes: sizes, weights, and colors stay the Cupertino
  /// defaults.
  static CupertinoThemeData cupertinoTheme() {
    const base = CupertinoTextThemeData();
    TextStyle withFamily(TextStyle style) =>
        style.copyWith(fontFamily: fontFamily);
    return CupertinoThemeData(
      textTheme: CupertinoTextThemeData(
        textStyle: withFamily(base.textStyle),
        actionTextStyle: withFamily(base.actionTextStyle),
        tabLabelTextStyle: withFamily(base.tabLabelTextStyle),
        navTitleTextStyle: withFamily(base.navTitleTextStyle),
        navLargeTitleTextStyle: withFamily(base.navLargeTitleTextStyle),
        navActionTextStyle: withFamily(base.navActionTextStyle),
        pickerTextStyle: withFamily(base.pickerTextStyle),
        dateTimePickerTextStyle: withFamily(base.dateTimePickerTextStyle),
      ),
    );
  }

  /// Theme-aware [TextStyle] for [AppBar] titles.
  static TextStyle appBarTitle(BuildContext context, ColorScheme colorScheme) =>
      TextStyle(
        fontSize: context.responsiveFont(20),
        fontFamily: fontFamily,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      );

  /// Theme-aware [TextStyle] for primary action buttons.
  static TextStyle buttonText(BuildContext context, ColorScheme colorScheme) =>
      TextStyle(
        fontSize: context.responsiveFont(buttonTextSize),
        fontWeight: FontWeight.w500,
        fontFamily: fontFamily,
        color: colorScheme.onPrimary,
        letterSpacing: 0.0,
      );
}
