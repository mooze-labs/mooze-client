import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'app_extra_colors.dart';

/// Produces [PinTheme] instances for the [Pinput] widget using active theme
/// tokens instead of hardcoded colors.
///
/// All factory methods accept the current [ColorScheme] and [AppExtraColors]
/// so they work correctly in both light and dark themes.
///
/// **Typical usage inside a widget:**
/// ```dart
/// final cs = Theme.of(context).colorScheme;
/// final extra = Theme.of(context).extension<AppExtraColors>()!;
///
/// Pinput(
///   defaultPinTheme: PinThemes.defaultTheme(cs, extra),
///   focusedPinTheme: PinThemes.focusedTheme(cs, extra),
///   filledPinTheme: PinThemes.filledTheme(cs, extra),
///   errorPinTheme: PinThemes.errorTheme(cs, extra),
///   disabledPinTheme: PinThemes.disabledTheme(cs, extra),
/// )
/// ```
class PinThemes {
  PinThemes._();

  // ── Base dimensions ───────────────────────────────────────────────────────

  static const double _cellSize = 56;

  // ── Factory methods ───────────────────────────────────────────────────────

  /// Default (idle) cell — primary-colored border, semi-transparent text.
  static PinTheme defaultTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => PinTheme(
    width: _cellSize,
    height: _cellSize,
    textStyle: TextStyle(
      fontSize: 20,
      // Use onSurface with reduced opacity to give the 'white60' look
      // in dark mode while still being readable in light mode.
      color: colorScheme.onSurface.withValues(alpha: 0.6),
      fontFamily: "roboto",
    ),
    decoration: BoxDecoration(
      border: Border.all(color: colorScheme.primary),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  /// Focused cell — highlighted background behind active input.
  static PinTheme focusedTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => defaultTheme(colorScheme, extraColors).copyWith(
    decoration: BoxDecoration(
      border: Border.all(color: colorScheme.primary),
      borderRadius: BorderRadius.circular(8),
      // pinBackground is a slightly lighter surface than pure black
      color: extraColors.pinBackground,
    ),
  );

  /// Filled cell — confirmed digit entered, uses the card surface color.
  static PinTheme filledTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => defaultTheme(colorScheme, extraColors).copyWith(
    decoration: BoxDecoration(
      border: Border.all(color: colorScheme.primary),
      borderRadius: BorderRadius.circular(8),
      // surfaceContainer maps to the swap-card background in dark mode
      color: colorScheme.surfaceContainer,
    ),
  );

  /// Error cell — wrong PIN / validation failure state.
  static PinTheme errorTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => defaultTheme(colorScheme, extraColors).copyWith(
    decoration: BoxDecoration(
      border: Border.all(color: colorScheme.error, width: 2),
      borderRadius: BorderRadius.circular(8),
      color: colorScheme.error.withValues(alpha: 0.1),
    ),
  );

  /// Disabled cell — input not interactive.
  static PinTheme disabledTheme(
    ColorScheme colorScheme,
    AppExtraColors extraColors,
  ) => defaultTheme(colorScheme, extraColors).copyWith(
    textStyle: TextStyle(
      fontSize: 20,
      color: extraColors.textTertiary,
      fontFamily: "roboto",
    ),
    decoration: BoxDecoration(
      border: Border.all(color: extraColors.textTertiary),
      borderRadius: BorderRadius.circular(8),
      color: extraColors.textTertiary.withValues(alpha: 0.1),
    ),
  );

  // ── BuildContext convenience helpers ──────────────────────────────────────
  // These are thin wrappers so call-sites that already hold a BuildContext
  // do not need to resolve colorScheme + extraColors manually.

  /// Resolves tokens from [context] and returns the default [PinTheme].
  static PinTheme defaultThemeOf(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final extra = Theme.of(context).extension<AppExtraColors>()!;
    return defaultTheme(cs, extra);
  }

  /// Resolves tokens from [context] and returns the focused [PinTheme].
  static PinTheme focusedThemeOf(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final extra = Theme.of(context).extension<AppExtraColors>()!;
    return focusedTheme(cs, extra);
  }

  /// Resolves tokens from [context] and returns the filled [PinTheme].
  static PinTheme filledThemeOf(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final extra = Theme.of(context).extension<AppExtraColors>()!;
    return filledTheme(cs, extra);
  }

  /// Resolves tokens from [context] and returns the error [PinTheme].
  static PinTheme errorThemeOf(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final extra = Theme.of(context).extension<AppExtraColors>()!;
    return errorTheme(cs, extra);
  }

  /// Resolves tokens from [context] and returns the disabled [PinTheme].
  static PinTheme disabledThemeOf(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final extra = Theme.of(context).extension<AppExtraColors>()!;
    return disabledTheme(cs, extra);
  }
}
