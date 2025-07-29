import 'package:flutter/material.dart';

class TitleAndSubtitle extends StatelessWidget {
  const TitleAndSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Como você quer começar?',
            style: textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Você pode criar uma nova carteira protegida por você, '
            'ou importar uma já existente com sua chave.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}