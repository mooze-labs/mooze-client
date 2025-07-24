import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'component_themes.dart';

class AppTheme {
  AppTheme._();
  
  static ThemeData darkTheme(BuildContext context) {
    final colorScheme = AppColors.darkColorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: "Inter",
      
      // Typography responsiva
      textTheme: AppTextStyles.buildResponsiveTextTheme(context, colorScheme),
      
      // App Bar Theme
      appBarTheme: ComponentThemes.appBarTheme(context, colorScheme),

      // Scaffold Theme
      scaffoldBackgroundColor: colorScheme.surfaceDim,

      // Card Theme
      cardTheme: ComponentThemes.cardTheme,

      // Input Decoration Theme
      inputDecorationTheme: ComponentThemes.inputDecorationTheme(colorScheme),

      // Button Themes
      elevatedButtonTheme: ComponentThemes.elevatedButtonTheme(context, colorScheme),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: ComponentThemes.bottomNavigationBarTheme,

      // Dropdown Menu Theme
      dropdownMenuTheme: ComponentThemes.dropdownMenuTheme,

      // Floating Action Button Theme
      floatingActionButtonTheme: ComponentThemes.floatingActionButtonTheme(colorScheme),

      // Divider Theme
      dividerTheme: ComponentThemes.dividerTheme,

      // Tile Theme
      listTileTheme: ComponentThemes.listTileTheme,
    );
  }
}