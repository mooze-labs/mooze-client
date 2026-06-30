import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

import '../providers/terms_acceptance_provider.dart';

class ImportWalletWidget extends ConsumerWidget {
  const ImportWalletWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hasAcceptedTerms = ref.watch(termsAcceptanceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return TextButton(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
      ),
      onPressed:
          hasAcceptedTerms ? () => context.push("/setup/import-wallet") : null,
      child: Text(
        t.first_access_import_wallet,
        style: textStyle.copyWith(
          color:
              hasAcceptedTerms
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
