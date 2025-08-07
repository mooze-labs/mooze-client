import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'app_colors.dart';

class PinThemes {
  PinThemes._();

  /// Returns the default theme for the Pinput widget.
  static PinTheme get defaultPinTheme => PinTheme(
    width: 56,
    height: 56,
    textStyle: const TextStyle(
      fontSize: 20,
      color: AppColors.textWhite60,
      fontFamily: "roboto",
    ),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.primaryColor),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  /// Returns the theme used when the Pinput field is focused.
  static PinTheme get focusedPinTheme => defaultPinTheme.copyWith(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.primaryColor, width: 1),
      borderRadius: BorderRadius.circular(8),
      color: AppColors.pinBackground,
    ),
  );

  /// Returns the theme applied when the Pinput field is filled.
  static PinTheme get filledPinTheme => defaultPinTheme.copyWith(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.primaryColor),
      borderRadius: BorderRadius.circular(8),
      color: AppColors.swapCardBackground,
    ),
  );

  /// Returns the error theme for the Pinput field.
  static PinTheme get errorPinTheme => defaultPinTheme.copyWith(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.negativeColor, width: 2),
      borderRadius: BorderRadius.circular(8),
      color: AppColors.negativeColor.withOpacity(0.1),
    ),
  );

  /// Returns the disabled theme for the Pinput field.
  static PinTheme get disabledPinTheme => defaultPinTheme.copyWith(
    textStyle: const TextStyle(
      fontSize: 20,
      color: AppColors.textTertiary,
      fontFamily: "roboto",
    ),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.textTertiary),
      borderRadius: BorderRadius.circular(8),
      color: AppColors.textTertiary.withOpacity(0.1),
    ),
  );
}
