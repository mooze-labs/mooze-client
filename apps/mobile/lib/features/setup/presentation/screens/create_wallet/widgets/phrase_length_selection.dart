import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_choice_row.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import '../providers/extended_phrase_provider.dart';

/// The two lengths of the recovery phrase, as one single-choice list in a
/// glass panel.
///
/// The check of the chosen length is the only brand color of the list.
class SeedPhraseSelector extends ConsumerWidget {
  const SeedPhraseSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final is24Words = ref.watch(extendedPhraseProvider);
    void choose(bool extended) =>
        ref.read(extendedPhraseProvider.notifier).state = extended;

    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SettingsChoiceRow(
            title: t.setup_seed_12_title,
            subtitle: t.setup_seed_12_desc,
            selected: !is24Words,
            onTap: () => choose(false),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: LabelSettings.horizontalPadding,
            endIndent: LabelSettings.horizontalPadding,
            color: AppSurfaces.hairline(context),
          ),
          SettingsChoiceRow(
            title: t.setup_seed_24_title,
            subtitle: t.setup_seed_24_desc,
            selected: is24Words,
            onTap: () => choose(true),
          ),
        ],
      ),
    );
  }
}
