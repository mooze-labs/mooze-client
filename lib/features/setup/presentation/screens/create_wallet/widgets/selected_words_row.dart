import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class SelectedWordsRow extends StatelessWidget {
  final List<int> positions;
  final Map<int, String> selectedWords;

  const SelectedWordsRow({
    super.key,
    required this.positions,
    required this.selectedWords,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      children: positions.map((position) {
        final isSelected = selectedWords.containsKey(position);
        final word = selectedWords[position] ?? '';

        final backgroundColor = isSelected
            ? colorScheme.primary.withValues(alpha:  0.3)
            : AppColors.recoveryPhraseBackground;

        final borderColor = isSelected
            ? colorScheme.primary
            : Colors.transparent;

        final numberColor = isSelected
            ? colorScheme.primary
            : AppColors.textPrimary;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: position != positions.last ? 15 : 0,
            ),
            padding: EdgeInsets.only(top: 10,bottom: 25, right: 10, left: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.toString(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: numberColor,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    word,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}