import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_extra_colors.dart';
import 'app_text_styles.dart';
import 'component_themes.dart';

/// Entry point for the app's [ThemeData] definitions.
///
/// Exposes [darkTheme] and [lightTheme] as the two supported themes.
/// Both are wired to the same component builder set in [ComponentThemes]
/// and differ only in their [ColorScheme] and [AppExtraColors] tokens.
///
/// Usage in your [MaterialApp]:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme(context),
///   darkTheme: AppTheme.darkTheme(context),
///   themeMode: ThemeMode.system, // or driven by user preference
/// )
/// ```
class AppTheme {
  AppTheme._();

  // ── Dark Theme ────────────────────────────────────────────────────────────

  static ThemeData darkTheme(BuildContext context) {
    const colorScheme = AppColors.darkColorScheme;
    const extraColors = AppExtraColors.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: "Inter",

      // Typography
      textTheme: AppTextStyles.buildResponsiveTextTheme(
        context,
        colorScheme,
        extraColors,
      ),

      // App Bar
      appBarTheme: ComponentThemes.appBarTheme(context, colorScheme),

      // Scaffold
      scaffoldBackgroundColor: colorScheme.surfaceDim,

      // Card
      cardTheme: ComponentThemes.cardTheme(colorScheme),

      // Input
      inputDecorationTheme: ComponentThemes.inputDecorationTheme(
        colorScheme,
        extraColors,
      ),

      // Buttons
      elevatedButtonTheme: ComponentThemes.elevatedButtonTheme(
        context,
        colorScheme,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: ComponentThemes.bottomNavigationBarTheme(
        colorScheme,
        extraColors,
      ),

      // Dropdown Menu
      dropdownMenuTheme: ComponentThemes.dropdownMenuTheme(
        colorScheme,
        extraColors,
      ),

      // Floating Action Button
      floatingActionButtonTheme:
          ComponentThemes.floatingActionButtonTheme(colorScheme),

      // Divider
      dividerTheme: ComponentThemes.dividerTheme(colorScheme),

      // List Tile
      listTileTheme: ComponentThemes.listTileTheme(colorScheme, extraColors),

      // Checkbox
      checkboxTheme: ComponentThemes.checkboxTheme(colorScheme),

      // Custom token extensions
      extensions: const [extraColors],
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────

  static ThemeData lightTheme(BuildContext context) {
    const colorScheme = AppColors.lightColorScheme;
    const extraColors = AppExtraColors.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: "Inter",

      // Typography
      textTheme: AppTextStyles.buildResponsiveTextTheme(
        context,
        colorScheme,
        extraColors,
      ),

      // App Bar
      appBarTheme: ComponentThemes.appBarTheme(context, colorScheme),

      // Scaffold
      scaffoldBackgroundColor: colorScheme.surfaceDim,

      // Card
      cardTheme: ComponentThemes.cardTheme(colorScheme),

      // Input
      inputDecorationTheme: ComponentThemes.inputDecorationTheme(
        colorScheme,
        extraColors,
      ),

      // Buttons
      elevatedButtonTheme: ComponentThemes.elevatedButtonTheme(
        context,
        colorScheme,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: ComponentThemes.bottomNavigationBarTheme(
        colorScheme,
        extraColors,
      ),

      // Dropdown Menu
      dropdownMenuTheme: ComponentThemes.dropdownMenuTheme(
        colorScheme,
        extraColors,
      ),

      // Floating Action Button
      floatingActionButtonTheme:
          ComponentThemes.floatingActionButtonTheme(colorScheme),

      // Divider
      dividerTheme: ComponentThemes.dividerTheme(colorScheme),

      // List Tile
      listTileTheme: ComponentThemes.listTileTheme(colorScheme, extraColors),

      // Checkbox
      checkboxTheme: ComponentThemes.checkboxTheme(colorScheme),

      // Custom token extensions
      extensions: const [extraColors],
    );
  }
}
