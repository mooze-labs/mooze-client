import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The words of a recovery phrase, three per row, numbered.
///
/// The grid scrolls only when the words do not fit its height.
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

  /// One word of the phrase on a glass lens: its number, muted, and the
  /// word. A long word or large text scales the line down instead of
  /// wrapping.
  Widget _buildWordCard(int number, String word, BuildContext context) {
    final style = context.textTheme.labelLarge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: GlassStyle.of(context).lensFill,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$number. ',
                style: style?.copyWith(
                  color: context.colors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: word,
                style: style?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
