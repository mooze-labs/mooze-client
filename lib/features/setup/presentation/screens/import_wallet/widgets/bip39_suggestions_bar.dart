import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/seed_phrase_provider.dart';

class Bip39SuggestionsBar extends ConsumerWidget {
  const Bip39SuggestionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(seedPhraseProvider);
    final notifier = ref.read(seedPhraseProvider.notifier);

    if (state.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children:
                state.suggestions.map((word) {
                  final isFirst = state.suggestions.indexOf(word) == 0;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: word == state.suggestions.last ? 0 : 8,
                      ),
                      child: _SuggestionChip(
                        word: word,
                        isFirst: isFirst,
                        onTap: () => notifier.confirmWord(word),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Chip de sugestão individual
class _SuggestionChip extends StatelessWidget {
  final String word;
  final bool isFirst;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.word,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isFirst
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isFirst)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.keyboard_return,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              Flexible(
                child: Text(
                  word,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        isFirst
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                    fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
