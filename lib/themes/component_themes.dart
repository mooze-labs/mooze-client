import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_extra_colors.dart';
import 'app_text_styles.dart';

/// Builds individual [ThemeData] component sub-themes.
///
/// Every public method accepts the active [ColorScheme] and [AppExtraColors]
/// so no raw [AppColors] constants appear inside the returned theme data.
/// All colour decisions are driven by theme tokens, making every method
/// safe for both dark and light themes without any branching.
class ComponentThemes {
  ComponentThemes._();

  // ── App Bar ───────────────────────────────────────────────────────────────

  static AppBarTheme appBarTheme(
    BuildContext context,
    ColorScheme colorScheme,
  ) => AppBarTheme(
    // surfaceDim is the darkest surface level — maps to the old solid black
    backgroundColor: colorScheme.surfaceDim,
    foregroundColor: colorScheme.onSurface,
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          colorScheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
      statusBarBrightness: colorScheme.brightness,
    ),
    titleTextStyle: AppTextStyles.appBarTitle(context, colorScheme),
    iconTheme: IconThemeData(color: colorScheme.primary),
  );

  // ── Card ──────────────────────────────────────────────────────────────────

  static CardThemeData cardTheme(ColorScheme colorScheme) => CardThemeData(
    // surfaceContainerLowest is the darkest card surface in Material 3
    color: colorScheme.surfaceContainerLowest,
    shadowColor: colorScheme.scrim.withValues(alpha: 0.5),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  // ── Input Decoration ──────────────────────────────────────────────────────

  static InputDecorationTheme inputDecorationTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => InputDecorationTheme(
    filled: true,
    // recoveryPhraseBackground is a custom dark purple-tinted surface
    fillColor: extraColors.recoveryPhraseBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    labelStyle: TextStyle(color: extraColors.textSecondary),
    hintStyle: TextStyle(color: extraColors.textTertiary),
  );

  // ── Legacy input theme (kept for DropdownMenu / legacy screens) ───────────

  /// Use [inputDecorationTheme] for new screens.
  static InputDecorationTheme legacyInputDecorationTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
    ),
    filled: true,
    fillColor: colorScheme.secondary,
    hintStyle: TextStyle(color: extraColors.textTertiary),
  );

  // ── Elevated Button ───────────────────────────────────────────────────────

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

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────

  static BottomNavigationBarThemeData bottomNavigationBarTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => BottomNavigationBarThemeData(
    backgroundColor: colorScheme.surface,
    selectedItemColor: colorScheme.primary,
    unselectedItemColor: extraColors.textTertiary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    showSelectedLabels: true,
    showUnselectedLabels: true,
  );

  // ── Legacy Bottom Navigation Bar (kept for legacy nav screens) ────────────

  /// Use [bottomNavigationBarTheme] for new screens.
  @Deprecated('Use bottomNavigationBarTheme instead.')
  static const BottomNavigationBarThemeData legacyBottomNavigationBarTheme =
      BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFFFF4081), // pinkAccent — dark-theme fallback
        unselectedItemColor: Colors.white,    // textPrimary — dark-theme fallback
        backgroundColor: Color(0xFF0F0F0F),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  // ── Dropdown Menu ─────────────────────────────────────────────────────────

  static DropdownMenuThemeData dropdownMenuTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(colorScheme.secondary),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
    ),
    inputDecorationTheme: legacyInputDecorationTheme(colorScheme, extraColors),
  );

  // ── Floating Action Button ────────────────────────────────────────────────

  static FloatingActionButtonThemeData floatingActionButtonTheme(
    ColorScheme colorScheme,
  ) => FloatingActionButtonThemeData(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  // ── Divider ───────────────────────────────────────────────────────────────

  static DividerThemeData dividerTheme(ColorScheme colorScheme) =>
      DividerThemeData(color: colorScheme.outline, thickness: 1);

  // ── List Tile ─────────────────────────────────────────────────────────────

  static ListTileThemeData listTileTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    tileColor: Colors.transparent,
    selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
    textColor: colorScheme.onSurface,
    iconColor: extraColors.textSecondary,
  );

  // ── Checkbox ──────────────────────────────────────────────────────────────

  static CheckboxThemeData checkboxTheme(ColorScheme colorScheme) =>
      CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: colorScheme.onPrimary),
        checkColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) return colorScheme.surface;
          return colorScheme.onPrimary;
        }),
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onPrimary;
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onPrimary;
        }),
      );
}
