import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../providers/seed_phrase_provider.dart';

/// How many words of the phrase the user typed, as a count and a bar.
///
/// The bar glides to each new count over [Motion.durationBase]. With
/// reduced motion it jumps.
class SeedPhraseProgressIndicator extends ConsumerWidget {
  const SeedPhraseProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(seedPhraseProvider);

    final targetCount = state.wordCount >= 12 ? 24 : 12;
    final progress = state.wordCount / targetCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // With large text the count moves below the label instead of
        // pushing it out of the row.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              t.setup_progress_label,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            // The count is text, so it keeps the text color: the brand
            // color fails the contrast of small text.
            Text(
              t.setup_progress_count(state.wordCount, targetCount),
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress.clamp(0.0, 1.0)),
            duration: Motion.of(context, Motion.durationBase),
            curve: Motion.curveMove,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppSurfaces.hairline(context),
              valueColor: AlwaysStoppedAnimation(context.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
