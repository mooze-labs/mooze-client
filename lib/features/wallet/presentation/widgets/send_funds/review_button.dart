import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import '../../providers/send_funds/send_validation_controller.dart';

class ReviewButton extends ConsumerWidget {
  const ReviewButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validation = ref.watch(sendValidationControllerProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          PrimaryButton(
            text: "Revisar Transação",
            onPressed:
                validation.canProceed
                    ? () async {
                      await ref
                          .read(sendValidationControllerProvider.notifier)
                          .validateTransaction();
                      final finalValidation = ref.read(
                        sendValidationControllerProvider,
                      );

                      if (finalValidation.canProceed) {
                        context.push('/send-funds/review-simple');
                      }
                    }
                    : null,
            isEnabled: validation.canProceed,
          ),
        ],
      ),
    );
  }
}

void reviewTransaction(BuildContext context, String address, int amount) {
  if (address.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Digite um endereço válido")));

    return;
  }

  if (amount <= 0) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Digite um valor válido")));

    return;
  }

  context.go("/reviewTransaction");
}
