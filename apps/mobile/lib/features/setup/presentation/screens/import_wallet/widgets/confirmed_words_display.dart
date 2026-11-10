import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../providers/seed_phrase_provider.dart';

/// The words the user confirmed, numbered, in one glass panel.
///
/// A tap on a word edits it, and its cross removes it. The word being
/// edited takes the brand border of a focused field.
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

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // With large text the action moves below the count instead of
          // pushing it out of the row.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                t.seed_confirmed_words_count(state.wordCount),
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.wordCount > 0)
                TextButton.icon(
                  onPressed: notifier.removeLastWord,
                  icon: const Icon(Icons.backspace_outlined, size: 18),
                  label: Text(t.seed_remove_last),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.textSecondary,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            // The panel has a narrow right padding for the header action.
            padding: const EdgeInsets.only(right: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final columns = MediaQuery.sizeOf(context).width >= 430 ? 3 : 2;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final (index, word) in state.confirmedWords.indexed)
                      SizedBox(
                        width: itemWidth,
                        child: _WordChip(
                          number: index + 1,
                          word: word,
                          isEditing: state.editingIndex == index,
                          onTap: () => notifier.startEditingWord(index),
                          onDelete: () => notifier.removeWordAt(index),
                        ),
                      ),
                  ],
                );
              },
            ),
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

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: _radius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            color: GlassStyle.of(context).lensFill,
            borderRadius: _radius,
            border: Border.all(
              color: isEditing
                  ? context.colorScheme.primary
                  : AppSurfaces.hairline(context),
              width: isEditing ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '$number',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  word,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: context.colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
