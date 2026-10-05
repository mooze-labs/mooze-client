import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/seed_phrase_option.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import '../providers/extended_phrase_provider.dart';

class SeedPhraseSelector extends ConsumerWidget {
  const SeedPhraseSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final is24Words = ref.watch(extendedPhraseProvider);

    return Column(
      children: [
        SeedPhraseOption(
          words: 12,
          title: t.setup_seed_12_title,
          description: t.setup_seed_12_desc,
          isSelected: !is24Words,
          isRecommended: false,
          onTap: () {
            ref.read(extendedPhraseProvider.notifier).state = false;
          },
        ),
        const SizedBox(height: 16),
        SeedPhraseOption(
          words: 24,
          title: t.setup_seed_24_title,
          description: t.setup_seed_24_desc,
          isSelected: is24Words,
          isRecommended: true,
          onTap: () {
            ref.read(extendedPhraseProvider.notifier).state = true;
          },
        ),
      ],
    );
  }
}
