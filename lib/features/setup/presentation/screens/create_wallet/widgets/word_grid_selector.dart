import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/word_selection_item.dart';

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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: shuffledWords.length,
      itemBuilder: (context, index) {
        final word = shuffledWords[index];
        final isSelected = selectedWords.containsValue(word);
        final wordPosition = getWordPosition(word);

        return Stack(
          children: [
            WordSelectionItem(
              word: word,
              isSelected: isSelected,
              position: wordPosition,
              onTap: () => onWordSelected(word),
            ),
          ],
        );
      },
    );
  }
}
