import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets.dart';

class NewTransactionScreen extends ConsumerWidget {
  const NewTransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enviar ativos"),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
        ).copyWith(top: 10, bottom: 24),
        child: Column(
          children: [
            _buildInstructionText(context),
            const SizedBox(height: 30),
            AssetSelectorWidget(),
            const SizedBox(height: 30),
            BalanceCard(),
            const SizedBox(height: 30),
            AddressField(),
            const SizedBox(height: 15),
            AmountField(),
          ],
        ),
      ),
    );
  }
}

Widget _buildInstructionText(BuildContext context) {
  return Center(
    child: RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          const TextSpan(text: "Escolha o ativo que quer enviar na "),
          TextSpan(
            text: "Mooze",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    ),
  );
}
