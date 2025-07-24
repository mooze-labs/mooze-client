import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/extensions/responsive_extensions.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle subtitle = TextStyle(
    color: AppColors.textWhite60,
    fontSize: 14,
  );
  
  static const TextStyle value = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const double buttonTextSize = 20.0;

  static TextTheme buildResponsiveTextTheme(BuildContext context, ColorScheme colorScheme) {
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: context.responsiveFont(57),
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: AppColors.textPrimary,
        fontFamily: "Inter",
      ),
      displayMedium: TextStyle(
        fontSize: context.responsiveFont(45),
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        fontFamily: "Inter",
      ),
      displaySmall: TextStyle(
        fontSize: context.responsiveFont(36),
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        fontFamily: "Inter",
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: context.responsiveFont(32),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: "Inter",
      ),
      headlineMedium: TextStyle(
        fontSize: context.responsiveFont(28),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: "Inter",
      ),
      headlineSmall: TextStyle(
        fontSize: context.responsiveFont(24),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: "Inter",
      ),

      // Title styles
      titleLarge: TextStyle(
        fontSize: context.responsiveFont(22),
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: "Inter",
      ),
      titleMedium: TextStyle(
        fontSize: context.responsiveFont(16),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: AppColors.textSecondary,
        fontFamily: "Inter",
      ),
      titleSmall: TextStyle(
        fontSize: context.responsiveFont(14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.textSecondary,
        fontFamily: "Inter",
      ),

      // Label styles
      labelLarge: TextStyle(
        fontSize: context.responsiveFont(14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
        fontFamily: "Inter",
      ),
      labelMedium: TextStyle(
        fontSize: context.responsiveFont(12),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
        fontFamily: "Inter",
      ),
      labelSmall: TextStyle(
        fontSize: context.responsiveFont(11),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textTertiary,
        fontFamily: "Inter",
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontSize: context.responsiveFont(16),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
        fontFamily: "Inter",
      ),
      bodyMedium: TextStyle(
        fontSize: context.responsiveFont(14),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: AppColors.textSecondary,
        fontFamily: "Inter",
      ),
      bodySmall: TextStyle(
        fontSize: context.responsiveFont(12),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: AppColors.textTertiary,
        fontFamily: "Inter",
      ),
    );
  }

  /// Returns a responsive text style for AppBar titles.
  static TextStyle appBarTitle(BuildContext context) => TextStyle(
    fontSize: context.responsiveFont(22),
    fontFamily: "roboto",
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Returns a responsive text style for buttons.
  static TextStyle buttonText(BuildContext context, ColorScheme colorScheme) => TextStyle(
    fontSize: context.responsiveFont(buttonTextSize),
    fontWeight: FontWeight.w500,
    fontFamily: "Inter",
    color: colorScheme.onPrimary,
    letterSpacing: 0.0,
  );
}