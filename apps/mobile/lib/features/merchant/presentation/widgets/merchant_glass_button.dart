import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The secondary button of Merchant Mode: a full-width glass capsule with
/// the primary text color.
///
/// It sits below or near the brand main button. Its neutral glass keeps
/// the brand color on the main action, and its text keeps the contrast of
/// body text in both themes.
class MerchantGlassButton extends StatelessWidget {
  const MerchantGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;

  /// Optional icon before the label.
  final PixIconData? icon;

  /// Height of the button, the same as the main button.
  static const double height = 55;

  /// Corners of the button, the same as the main button, so the two read
  /// as a pair.
  static const BorderRadius radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textPrimary;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: PressScale(
        child: SizedBox(
          width: double.infinity,
          child: LiquidGlass(
            borderRadius: radius,
            blurBackdrop: false,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: onPressed,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: height),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          PixIcon(icon!, size: 20, color: color),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
