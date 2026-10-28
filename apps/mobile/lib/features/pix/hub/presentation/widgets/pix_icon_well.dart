import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Meaning of a Pix icon well or status.
///
/// [neutral] is the default for list rows. The brand pink stays on the main
/// action of a screen. The other tones mark a state, always together with a
/// text or an icon shape, never by color alone.
enum PixTone { neutral, brand, positive, warning, negative }

/// Returns the foreground color of [tone].
Color pixToneColor(BuildContext context, PixTone tone) => switch (tone) {
  PixTone.neutral => context.colors.textPrimary,
  PixTone.brand => context.colors.primaryColor,
  PixTone.positive => context.colors.positiveColor,
  PixTone.warning => context.appColors.warning,
  PixTone.negative => context.colors.negativeColor,
};

/// A round well that holds the icon of a row, a card, or an empty state.
///
/// The neutral well is a glass lens: it reads as part of the glass panel
/// around it. A colored tone fills the well with a light tint of its color.
class PixIconWell extends StatelessWidget {
  const PixIconWell({
    super.key,
    required this.icon,
    this.tone = PixTone.neutral,
    this.size = defaultSize,
  });

  /// Diameter of a well in a list row.
  static const double defaultSize = 40;

  final PixIconData icon;
  final PixTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = pixToneColor(context, tone);
    final isNeutral = tone == PixTone.neutral;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNeutral
            ? GlassStyle.of(context).lensFill
            : color.withValues(alpha: 0.14),
        border: Border.all(
          color: isNeutral
              ? AppSurfaces.hairline(context)
              : color.withValues(alpha: 0.24),
        ),
      ),
      // The icon takes half of the well, as in the wallet action buttons.
      child: PixIcon(icon, size: size / 2, color: color),
    );
  }
}
