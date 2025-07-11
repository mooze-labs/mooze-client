import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/setup/presentation/create_wallet/providers/extended_phrase_provider.dart';

class PhraseLengthSelection extends ConsumerWidget {
  const PhraseLengthSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        RadioListTile(
          title: Text('12 palavras'),
          value: false,
          groupValue: ref.watch(extendedPhraseProvider),
          onChanged: (value) {
            ref.read(extendedPhraseProvider.notifier).state = value!;
          },
        ),
        RadioListTile(
          title: Text('24 palavras'),
          value: true,
          groupValue: ref.watch(extendedPhraseProvider),
          onChanged: (value) {
            ref.read(extendedPhraseProvider.notifier).state = value!;
          },
        ),
      ],
    );
  }
}
