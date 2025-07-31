import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/terms_acceptance_provider.dart';

class ImportWalletWidget extends ConsumerWidget {
  const ImportWalletWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAcceptedTerms = ref.watch(termsAcceptanceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return TextButton(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent), 
          splashFactory: NoSplash.splashFactory, 
      ),
      onPressed: hasAcceptedTerms ? () => context.go("/setup/import-wallet") : null,
      child: Text(
        'Importar carteira',
        style: textStyle.copyWith(
          color: hasAcceptedTerms
              ? colorScheme.onPrimary
              : colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
