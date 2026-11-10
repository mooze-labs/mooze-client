import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

import '../providers/terms_acceptance_provider.dart';

/// The second way in, below the main action. It waits for the terms.
///
/// It is a quiet text action, so the brand color stays on the main action.
class ImportWalletWidget extends ConsumerWidget {
  const ImportWalletWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hasAcceptedTerms = ref.watch(termsAcceptanceProvider);
    return PinTextAction(
      label: t.first_access_import_wallet,
      onPressed: hasAcceptedTerms
          ? () => context.push("/setup/import-wallet")
          : null,
    );
  }
}
