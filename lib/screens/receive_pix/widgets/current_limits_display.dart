import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/mooze/user_provider.dart';
import 'package:mooze_mobile/screens/receive_pix/providers/user_info_provider.dart';
import 'package:mooze_mobile/services/mooze/user.dart';

class CurrentLimitsDisplay extends ConsumerWidget {
  const CurrentLimitsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userInfoProvider);

    return user.when(
      data: (user) {
        return Column(
          children: [
            Text(
              "Limite atual: R\$ ${((user?.allowedSpending ?? 25000) / 100).toStringAsFixed(2)}",
            ),
            Text("Valor mínimo: R\$ 20,00"),
            Text(
              "Continue fazendo mais PIX para aumentar seu limite.",
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
      error: (error, stack) {
        return const Text("Erro ao carregar limites.");
      },
      loading: () {
        return const Text("Carregando limites...");
      },
    );
  }
}
