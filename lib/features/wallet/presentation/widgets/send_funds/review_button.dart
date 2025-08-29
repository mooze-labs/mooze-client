import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/amount_provider.dart';

class ReviewButton extends ConsumerWidget {
  const ReviewButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.read(addressStateProvider);
    final amount = ref.read(amountStateProvider);

    final isEnabled = address.isNotEmpty && (amount > 0);

    return PrimaryButton(
      text: "Revisar transação",
      onPressed: () => reviewTransaction(context, address, amount),
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
