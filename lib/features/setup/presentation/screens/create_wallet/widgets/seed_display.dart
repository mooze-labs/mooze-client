import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class MnemonicGridDisplay extends StatelessWidget {
  final String mnemonic;

  const MnemonicGridDisplay({required this.mnemonic, super.key});

  @override
  Widget build(BuildContext context) {
    final words = mnemonic.split(" ");

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = 3;
        final aspectRatio = _calculateAspectRatio(
          constraints.maxWidth,
          crossAxisCount,
        );
        final needsScroll = _needsScroll(
          wordCount: words.length,
          constraints: constraints,
          crossAxisCount: crossAxisCount,
          aspectRatio: aspectRatio,
        );

        return GridView.builder(
          physics:
              needsScroll
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
          shrinkWrap: !needsScroll,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: aspectRatio,
          ),
          itemCount: words.length,
          itemBuilder: (context, index) {
            return _buildWordCard(index + 1, words[index], context);
          },
        );
      },
    );
  }

  double _calculateAspectRatio(double availableWidth, int crossAxisCount) {
    final spacing = 12.0;
    final itemWidth =
        (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
    const minItemHeight = 40.0;
    double ratio = itemWidth / minItemHeight;

    return ratio.clamp(2.0, 2.8);
  }

  bool _needsScroll({
    required int wordCount,
    required BoxConstraints constraints,
    required int crossAxisCount,
    required double aspectRatio,
  }) {
    final rowCount = (wordCount / crossAxisCount).ceil();
    final itemHeight = (constraints.maxWidth / crossAxisCount) / aspectRatio;
    final totalHeight = rowCount * itemHeight + (rowCount - 1) * 12;
    return totalHeight > constraints.maxHeight;
  }

  Widget _buildWordCard(int number, String word, BuildContext context) {
    final theme = Theme.of(context).textTheme.labelLarge;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.recoveryPhraseBackground,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$number. ',
                style: theme?.copyWith(color: AppColors.textQuintary),
              ),
              TextSpan(text: word, style: theme),
            ],
          ),
        ),
      ),
    );
  }
}
