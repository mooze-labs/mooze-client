import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class ComponentThemes {
  ComponentThemes._();

  /// App Bar Theme
  static AppBarTheme appBarTheme(
    BuildContext context,
    ColorScheme colorScheme,
  ) => AppBarTheme(
    backgroundColor: AppColors.backgroundColor,
    foregroundColor: colorScheme.onSurface,
    elevation: 0,
    centerTitle: true,
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    titleTextStyle: AppTextStyles.appBarTitle(context),
    iconTheme: const IconThemeData(color: AppColors.primaryColor),
  );

  /// Card Theme
  static CardThemeData get cardTheme => CardThemeData(
    color: AppColors.backgroundCard,
    shadowColor: AppColors.absoluteBlack.withValues(alpha: 0.5),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  /// Input Decoration Theme
  static InputDecorationTheme inputDecorationTheme(ColorScheme colorScheme) =>
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.recoveryPhraseBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.swapLinearBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.swapLinearBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.negativeColor),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      );

  /// Legacy Input Decoration Theme
  static InputDecorationTheme get legacyInputDecorationTheme =>
      InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
        ),
        filled: true,
        fillColor: AppColors.secondaryColor,
        hintStyle: TextStyle(color: AppColors.greyShade500),
      );

  /// Elevated Button Theme
  static ElevatedButtonThemeData elevatedButtonTheme(
    BuildContext context,
    ColorScheme colorScheme,
  ) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      textStyle: AppTextStyles.buttonText(context, colorScheme),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  /// Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData get bottomNavigationBarTheme =>
      const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceColor,
        selectedItemColor: AppColors.pinkAccent,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  /// Legacy Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData get legacyBottomNavigationBarTheme =>
      const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.pinkAccent,
        unselectedItemColor: AppColors.textPrimary,
        backgroundColor: Color.fromARGB(255, 15, 15, 15),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  /// Dropdown Menu Theme
  static DropdownMenuThemeData get dropdownMenuTheme => DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(AppColors.secondaryColor),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
    ),
    inputDecorationTheme: legacyInputDecorationTheme,
  );

  /// Floating Action Button Theme
  static FloatingActionButtonThemeData floatingActionButtonTheme(
    ColorScheme colorScheme,
  ) => FloatingActionButtonThemeData(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  /// Divider Theme
  static DividerThemeData get dividerTheme =>
      const DividerThemeData(color: AppColors.swapLinearBorder, thickness: 1);

  /// List Tile Theme
  static ListTileThemeData get listTileTheme => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    tileColor: Colors.transparent,
    selectedTileColor: AppColors.primaryColor.withValues(alpha: 0.1),
    textColor: AppColors.textPrimary,
    iconColor: AppColors.textSecondary,
  );

  static CheckboxThemeData get checkboxTheme => CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    side: BorderSide(color: AppColors.onPrimaryColor),
    checkColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.black;
      }
      return AppColors.onPrimaryColor;
    }),
    fillColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.white;
      }
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryColor;
      }
      return Colors.white;
    }),
  );
}
