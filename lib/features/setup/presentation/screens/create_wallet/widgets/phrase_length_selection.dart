import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/seed_phrase_option.dart';
import '../providers/extended_phrase_provider.dart';

class SeedPhraseSelector extends ConsumerWidget {
  const SeedPhraseSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final is24Words = ref.watch(extendedPhraseProvider);

    return Column(
      children: [
        SeedPhraseOption(
          words: 12,
          title: '12 Palavras',
          description:
              'Mais prática e rápida de configurar. Recomendada\npara iniciantes ou quem prefere simplicidade sem\nabrir mão da segurança.',
          isSelected: !is24Words,
          isRecommended: false,
          onTap: () {
            ref.read(extendedPhraseProvider.notifier).state = false;
          },
        ),
        const SizedBox(height: 16),
        SeedPhraseOption(
          words: 24,
          title: '24 Palavras (recomendado)',
          description:
              'Proporciona mais segurança. Recomendada para\nquem deseja proteger valores maiores ou busca o\nmáximo de segurança.',
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
