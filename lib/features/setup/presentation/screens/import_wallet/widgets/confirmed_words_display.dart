import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

import '../providers/seed_phrase_provider.dart';

class ConfirmedWordsDisplay extends ConsumerWidget {
  const ConfirmedWordsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(seedPhraseProvider);
    final notifier = ref.read(seedPhraseProvider.notifier);

    if (state.confirmedWords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.seed_confirmed_words_count(state.wordCount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (state.wordCount > 0)
                TextButton.icon(
                  onPressed: notifier.removeLastWord,
                  icon: const Icon(Icons.backspace, size: 16),
                  label: Text(t.seed_remove_last),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final columns = MediaQuery.sizeOf(context).width >= 430 ? 3 : 2;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children:
                    state.confirmedWords.asMap().entries.map((entry) {
                      final index = entry.key;
                      final word = entry.value;
                      final isEditing = state.editingIndex == index;
                      return SizedBox(
                        width: itemWidth,
                        child: _WordChip(
                          number: index + 1,
                          word: word,
                          isEditing: isEditing,
                          onTap: () => notifier.startEditingWord(index),
                          onDelete: () => notifier.removeWordAt(index),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final int number;
  final String word;
  final bool isEditing;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _WordChip({
    required this.number,
    required this.word,
    this.isEditing = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color:
              isEditing
                  ? Theme.of(context).colorScheme.tertiaryContainer
                  : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          border:
              isEditing
                  ? Border.all(
                    color: Theme.of(context).colorScheme.tertiary,
                    width: 2,
                  )
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isEditing
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      isEditing
                          ? Theme.of(context).colorScheme.onTertiary
                          : Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                word,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isEditing
                          ? Theme.of(context).colorScheme.onTertiaryContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                softWrap: true,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: (isEditing
                            ? Theme.of(context).colorScheme.onTertiaryContainer
                            : Theme.of(context).colorScheme.onPrimaryContainer)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
