import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One word to choose in the confirmation of the recovery phrase.
///
/// A chosen word takes the brand border and shows the position it fills,
/// in a badge inside the chip, so the badge never leaves the grid.
class WordSelectionItem extends StatelessWidget {
  final String word;
  final bool isSelected;

  /// The position the word fills, from 1, or null while it is not chosen.
  final int? position;
  final VoidCallback onTap;

  const WordSelectionItem({
    required this.word,
    required this.isSelected,
    required this.position,
    required this.onTap,
    super.key,
  });

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.durationFast);
    final position = this.position;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: _radius,
          child: AnimatedContainer(
            duration: duration,
            curve: Motion.curveMove,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: GlassStyle.of(context).lensFill,
              borderRadius: _radius,
              border: Border.all(
                color: isSelected
                    ? context.colorScheme.primary
                    : AppSurfaces.hairline(context),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected && position != null) ...[
                    _PositionBadge(position: position),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    word,
                    maxLines: 1,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
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

/// The position a chosen word fills, on the brand fill.
class _PositionBadge extends StatelessWidget {
  final int position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        '$position',
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
