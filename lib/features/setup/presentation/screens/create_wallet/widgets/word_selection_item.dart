import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class WordSelectionItem extends StatelessWidget {
  final String word;
  final bool isSelected;
  final int? position;
  final VoidCallback onTap;

  const WordSelectionItem({
    required this.word,
    required this.isSelected,
    required this.position,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor =
        isSelected
            ? theme.colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.1);
    double? borderWidth = isSelected ? 2.0 : 1;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            padding: EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                word,
                style: theme.textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (isSelected && position != null)
          Positioned(
            top: -8,
            right: -8,
            child: _PositionBadge(position: position!),
          ),
      ],
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$position',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
}
