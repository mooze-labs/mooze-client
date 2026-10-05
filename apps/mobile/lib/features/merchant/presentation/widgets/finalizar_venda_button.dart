import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class FinalizarVendaButton extends StatelessWidget {
  /// Callback when button is pressed (only fires if enabled)
  final VoidCallback onPressed;

  /// Current cart total (used for validation)
  /// If null, button is enabled (assumes validation happens elsewhere)
  final double? totalOrderAmount;

  /// Global key for the button (used for tutorials)
  final GlobalKey? buttonKey;

  const FinalizarVendaButton({
    super.key,
    required this.onPressed,
    this.totalOrderAmount,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallScreen = screenHeight < 650;
    final isSmallScreen = screenHeight < 700 && screenHeight >= 650;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 12 : 16,
      ).copyWith(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: PlatformSafeArea(
        androidTop: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              key: buttonKey,
              text: t.merchant_finalize_sale_button,
              onPressed: onPressed,
              isEnabled: totalOrderAmount == null || totalOrderAmount! >= 20.0,
              height: isVerySmallScreen ? 48 : (isSmallScreen ? 52 : 56),
            ),
            if (totalOrderAmount != null &&
                totalOrderAmount! > 0 &&
                totalOrderAmount! < 20.0) ...[
              SizedBox(height: isVerySmallScreen ? 6 : 8),
              Text(
                t.merchant_min_sale_short,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
