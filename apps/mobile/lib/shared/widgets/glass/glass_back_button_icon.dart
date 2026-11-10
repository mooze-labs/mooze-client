import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The back button icon of the app: a chevron on a round glass button, the
/// back button of Merchant Mode.
///
/// The theme makes it the icon of every [BackButton] (see
/// [ActionIconThemeData.backButtonIconBuilder]), so the app bars show it
/// without a custom leading. The [BackButton] keeps the tap, the tooltip
/// and the semantics.
///
/// The glass fills the whole button: it overflows the icon slot into the
/// button padding, so the ink overlay of the button covers the glass
/// exactly. An app bar clips its toolbar, so the glass takes the short
/// control shadows.
class GlassBackButtonIcon extends StatelessWidget {
  const GlassBackButtonIcon({super.key});

  /// Diameter of the glass circle.
  static const double size = 44;

  /// Space that [IconButton] keeps around its icon.
  static const double _buttonPadding = 8;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size - 2 * _buttonPadding,
      child: OverflowBox(
        minWidth: size,
        maxWidth: size,
        minHeight: size,
        maxHeight: size,
        child: LiquidGlass(
          blurBackdrop: false,
          shadows: GlassStyle.of(context).controlShadows,
          child: Center(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
