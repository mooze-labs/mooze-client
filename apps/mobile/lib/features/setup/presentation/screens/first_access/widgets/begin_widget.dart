import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/providers/terms_acceptance_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

/// The main action of the first screen. It waits for the terms.
class BeginWidget extends ConsumerWidget {
  const BeginWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final termsAccepted = ref.watch(termsAcceptanceProvider);

    return PrimaryButton(
      text: t.first_access_create_wallet,
      onPressed: termsAccepted
          ? () => context.push("/setup/create-wallet/configure-seeds")
          : null,
      isEnabled: termsAccepted,
    );
  }
}
