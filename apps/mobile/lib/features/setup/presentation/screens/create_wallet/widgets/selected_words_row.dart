import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The slots of the words that the confirmation asks for, in order.
///
/// Each slot looks like a glass input: the lens fill and a hairline. The
/// next slot to fill has the brand border of a focused field, so the user
/// sees which word comes next.
class SelectedWordsRow extends StatelessWidget {
  /// The asked positions in the phrase, from 1, in ascending order.
  final List<int> positions;
  final Map<int, String> selectedWords;

  const SelectedWordsRow({
    super.key,
    required this.positions,
    required this.selectedWords,
  });

  @override
  Widget build(BuildContext context) {
    final next = positions
        .where((position) => !selectedWords.containsKey(position))
        .firstOrNull;

    return Row(
      children: [
        for (final (index, position) in positions.indexed) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: _WordSlot(
              position: position,
              word: selectedWords[position],
              isNext: position == next,
            ),
          ),
        ],
      ],
    );
  }
}

class _WordSlot extends StatelessWidget {
  final int position;

  /// The chosen word, or null while the slot is empty.
  final String? word;
  final bool isNext;

  const _WordSlot({
    required this.position,
    required this.word,
    required this.isNext,
  });

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final duration = Motion.of(context, Motion.durationFast);
    final word = this.word;

    return Semantics(
      label: '${t.setup_seed_word_label(position)}${word ?? ''}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        curve: Motion.curveMove,
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: GlassStyle.of(context).lensFill,
          borderRadius: _radius,
          border: Border.all(
            color: isNext
                ? context.colorScheme.primary
                : AppSurfaces.hairline(context),
            width: isNext ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$position',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: duration,
              switchInCurve: Motion.curveEnter,
              switchOutCurve: Motion.curveExit,
              child: SizedBox(
                key: ValueKey(word),
                width: double.infinity,
                child: word == null
                    ? const SizedBox(height: 20)
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          word,
                          maxLines: 1,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
