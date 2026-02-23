import 'package:flutter/material.dart';

class TitleAndSubtitleCreateWallet extends StatelessWidget {
  final String title;
  final String highlighted;
  final String subtitle;

  const TitleAndSubtitleCreateWallet({
    super.key,
    required this.title,
    required this.highlighted,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.displaySmall,
            children: [
              TextSpan(text: title),
              TextSpan(
                text: highlighted,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }
}
