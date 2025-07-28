import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import '../providers.dart';

class AccountLimitsDisplay extends ConsumerWidget {
  const AccountLimitsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountLimit = ref.read(amountLimitProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        accountLimit.when(data: (data) =>
            InfoRow(
              label: 'Limite atual',
              value: 'R\$ $data',
              labelColor: Colors.white70,
              valueColor: Colors.white,
              fontSize: context.responsiveFont(14),
            ),
            error: (error, stackTrace) =>
                InfoRow(
                  label: 'Limite atual',
                  value: 'R\$ 500.00',
                  labelColor: Colors.white70,
                  valueColor: Colors.white,
                  fontSize: context.responsiveFont(14),
                ),
            loading: () => ShimmerInfoRow(label: "Limite atual")),
        SizedBox(height: 6),
        InfoRow(
          label: 'Valor mínimo',
          value: 'R\$ 20,00',
          labelColor: Colors.white70,
          valueColor: Colors.white,
          fontSize: context.responsiveFont(14),
        ),
        SizedBox(height: 6),
        InfoRow(
          label: 'Limite diário por CPF/CNPJ',
          value: 'R\$ 5.000,00',
          labelColor: Colors.white70,
          valueColor: Colors.white,
          fontSize: context.responsiveFont(14),
        ),
      ],
    );
  }
}