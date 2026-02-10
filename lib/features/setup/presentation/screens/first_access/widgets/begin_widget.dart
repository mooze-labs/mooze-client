import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/providers/terms_acceptance_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

class BeginWidget extends ConsumerWidget {
  const BeginWidget({super.key});
  static const double _horizontalPadding = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAccepted = ref.watch(termsAcceptanceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: PrimaryButton(
        text: 'Criar Carteira',
        onPressed:
            termsAccepted
                ? () {
                  context.push("/setup/create-wallet/configure-seeds");
                }
                : null,
        isEnabled: termsAccepted,
      ),
    );
  }
}
