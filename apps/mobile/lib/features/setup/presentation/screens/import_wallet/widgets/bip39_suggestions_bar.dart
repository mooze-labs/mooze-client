import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../providers/seed_phrase_provider.dart';

/// The BIP39 words that start with the typed text, above the keyboard.
///
/// The first word is the one the space key confirms: it has the brand
/// border and the return glyph, so the shortcut shows without color alone.
class Bip39SuggestionsBar extends ConsumerWidget {
  const Bip39SuggestionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(seedPhraseProvider);
    final notifier = ref.read(seedPhraseProvider.notifier);

    if (state.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Without the keyboard, the bar keeps clear of the home indicator.
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        BackdropPageScaffold.gutter,
        8,
        BackdropPageScaffold.gutter,
        8 + bottom,
      ),
      child: Row(
        children: [
          for (final (index, word) in state.suggestions.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: _SuggestionChip(
                word: word,
                isFirst: index == 0,
                onTap: () => notifier.confirmWord(word),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One suggested word.
class _SuggestionChip extends StatelessWidget {
  final String word;
  final bool isFirst;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.word,
    required this.isFirst,
    required this.onTap,
  });

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GlassStyle.of(context).lensFill,
      shape: RoundedRectangleBorder(
        borderRadius: _radius,
        side: BorderSide(
          color: isFirst
              ? context.colorScheme.primary
              : AppSurfaces.hairline(context),
          width: isFirst ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: _radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFirst)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.keyboard_return_rounded,
                      size: 16,
                      color: context.colors.textSecondary,
                    ),
                  ),
                Flexible(
                  child: Text(
                    word,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
