import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/word_selection_item.dart';

/// The words to choose from, three per row.
///
/// The grid does not scroll: the page around it scrolls when the words do
/// not fit, for example with large text.
class WordSelectionGrid extends StatelessWidget {
  final List<String> shuffledWords;

  final Map<int, String> selectedWords;

  final Function(String) onWordSelected;

  final int? Function(String) getWordPosition;

  const WordSelectionGrid({
    super.key,
    required this.shuffledWords,
    required this.selectedWords,
    required this.onWordSelected,
    required this.getWordPosition,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        // A word keeps a 48 pt touch target at any width.
        mainAxisExtent: 52,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: shuffledWords.length,
      itemBuilder: (context, index) {
        final word = shuffledWords[index];
        return WordSelectionItem(
          word: word,
          isSelected: selectedWords.containsValue(word),
          position: getWordPosition(word),
          onTap: () => onWordSelected(word),
        );
      },
    );
  }
}
