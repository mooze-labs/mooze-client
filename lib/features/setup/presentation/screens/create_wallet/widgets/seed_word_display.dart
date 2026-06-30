import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class SeedWordDisplay extends StatelessWidget {
  final String word;
  final int position;

  const SeedWordDisplay({
    required this.word,
    required this.position,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Text(
            t.setup_seed_word_label(position),
            style: const TextStyle(fontFamily: "Inter"),
          ),
          SizedBox(width: (position >= 10) ? 8 : 14),
          Expanded(
            child: Text(word, style: const TextStyle(fontFamily: "Inter")),
          ),
        ],
      ),
    );
  }
}
