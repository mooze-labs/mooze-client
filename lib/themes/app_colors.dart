import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color backgroundColor = Color(0xFF0A0A0A);
  static const Color backgroundCard = Color(0xFF0A0A0A);
  static const Color primaryColor = Color(0xFFEA1E63);
  static const Color pinkAccent = Colors.pinkAccent;
  static const Color onPrimaryColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9194A6);
  static const Color textTertiary = Color(0xFF7C7C7C);
  static const Color textQuartiary = Color(0xFFC2C2C2);
  static const Color textQuintary = Color(0xFFA6A0BB);
  static const Color textWhite60 = Colors.white60;

  // Status Colors
  static const Color positiveColor = Color(0xFF32B153);
  static const Color negativeColor = Color(0xFFD73131);
  static const Color errorColor = Colors.red;

  // Surface Colors
  static const Color absoluteBlack = Color(0xFF000000);
  static const Color surfaceColor = Color(0xFF141722);
  static const Color swapCardBackground = Color(0xFF141722);
  static const Color swapLinearBorder = Color(0xFF2D2E2A);
  static const Color recoveryPhraseBackground = Color(0xFF1C1924);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFF212121);
  static const Color greyShade500 = Color(0xFF9E9E9E);

  static const ColorScheme darkColorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    // Primary
    primary: primaryColor,
    onPrimary: onPrimaryColor,
    primaryContainer: Color(0xFF4A0E2A),
    onPrimaryContainer: Color(0xFFFFD9E4),

    // Secondary
    secondary: secondaryColor,
    onSecondary: textWhite60,
    secondaryContainer: Color(0xFF383838),
    onSecondaryContainer: Color(0xFFE6E1E5),

    // Tertiary
    tertiary: positiveColor,
    onTertiary: textPrimary,
    tertiaryContainer: Color(0xFF0F3A1C),
    onTertiaryContainer: Color(0xFFB7F397),

    // Errors
    error: negativeColor,
    onError: textPrimary,
    errorContainer: Color(0xFF410E0B),
    onErrorContainer: Color(0xFFF2B8B5),

    // Surface
    surface: surfaceColor,
    onSurface: textPrimary,
    surfaceTint: primaryColor,
    surfaceDim: backgroundColor,
    surfaceBright: Color(0xFF1F1F1F),
    surfaceContainerLowest: absoluteBlack,
    surfaceContainerLow: backgroundColor,
    surfaceContainer: swapCardBackground,
    surfaceContainerHigh: Color(0xFF1C1B1F),
    surfaceContainerHighest: Color(0xFF26252A),

    // Outline
    outline: swapLinearBorder,
    outlineVariant: textTertiary,

    // Inverse Colors
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF9F4052),

    // Overlay
    scrim: absoluteBlack,
    shadow: absoluteBlack,
  );
}
