import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The main action of Merchant Mode, pinned above the bottom edge.
///
/// It sits on the screen backdrop, like the main buttons of the Pix flows.
/// Below the minimum sale amount it is disabled, and a hint with an info
/// icon says why. The hint grows in and out over [Motion.durationEmphasis].
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

  /// Smallest amount of a sale, in BRL.
  static const double minSaleAmount = 20.0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final amount = totalOrderAmount;
    final belowMinimum = amount != null && amount > 0 && amount < minSaleAmount;
    final isShortScreen = MediaQuery.sizeOf(context).height < 700;

    // The same bottom spacing as the main button of the Pix flows.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              key: buttonKey,
              text: t.merchant_finalize_sale_button,
              onPressed: onPressed,
              isEnabled: amount == null || amount >= minSaleAmount,
              height: isShortScreen ? 50 : 55,
            ),
            SizeFadeSwitcher(
              child: belowMinimum
                  ? Padding(
                      key: const ValueKey('min-sale'),
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PixIcon(
                            PixIcons.info,
                            size: 14,
                            color: context.colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              t.merchant_min_sale_short,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('no-hint'),
                      width: double.infinity,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
