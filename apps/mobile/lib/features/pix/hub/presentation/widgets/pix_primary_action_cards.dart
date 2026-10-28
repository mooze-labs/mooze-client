import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Corner radius of the hub action cards.
const BorderRadius _cardRadius = BorderRadius.all(Radius.circular(16));

/// Leading action of the hub, drawn full width.
///
/// Receiving is the operation the hub puts first, so it gets the whole row
/// and the brand color. The horizontal layout keeps the card compact.
///
/// A press scales the card with [PressScale].
class PixHighlightActionCard extends StatelessWidget {
  final PixIconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const PixHighlightActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  /// Joins the last two words with a no-break space. A wrapped description
  /// then never ends with one word alone on the last line.
  static String _keepLastWordsTogether(String text) {
    final index = text.trimRight().lastIndexOf(' ');
    if (index <= 0) return text;
    return '${text.substring(0, index)} ${text.substring(index + 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = colors.onPrimaryColor;

    // One node with the label and the description. The visible texts stay
    // out of the tree, so a screen reader reads each text once.
    return Semantics(
      button: true,
      label: label,
      hint: description,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _cardRadius,
              // Same color pair as the Pix button of the navigation bar. The
              // darker end sits under the text: white text on it passes
              // 5.4:1 or more. On the brighter end it gets only 4.3:1.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.navBarFabBackground, colors.primaryColor],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: _cardRadius,
              splashColor: foreground.withValues(alpha: 0.12),
              highlightColor: foreground.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: foreground.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: PixIcon(icon, size: 26, color: foreground),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: context.textTheme.titleMedium?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _keepLastWordsTogether(description),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: foreground.withValues(alpha: 0.9),
                              letterSpacing: 0,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: foreground.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: PixIcon(
                        PixIcons.arrowRight,
                        size: 18,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action of the hub, drawn as one half of the row below the
/// highlighted card.
///
/// The surface is a glass panel and only the icon uses the brand color, so
/// the card stays below the receive card in the hierarchy. A press scales
/// the card with [PressScale].
class PixCompactActionCard extends StatelessWidget {
  final PixIconData icon;
  final String label;
  final VoidCallback onTap;

  const PixCompactActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        // A glass card: one step below the receive card, which keeps the
        // only brand fill.
        child: GlassPanel(
          borderRadius: _cardRadius,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  PixIconWell(icon: icon, tone: PixTone.brand),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
