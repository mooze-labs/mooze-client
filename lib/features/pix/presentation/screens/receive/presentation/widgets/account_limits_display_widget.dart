import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

class AccountLimitsDisplay extends ConsumerWidget {
  final VoidCallback? onToggleView;

  const AccountLimitsDisplay({super.key, this.onToggleView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsData = ref.watch(levelsProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: onToggleView,
          child: InfoRow(
            label: 'Meus limites',
            value: 'Ocultar Limite',
            labelColor: Colors.white,
            valueColor: AppColors.primaryColor,
            fontSize: context.responsiveFont(14),
          ),
        ),
        const SizedBox(height: 6),
        levelsData.when(
          data:
              (data) => Column(
                children: [
                  InfoRow(
                    label: 'Limite diário',
                    value: 'R\$ ${data.allowedSpending.toStringAsFixed(2)}',
                    labelColor: Colors.white70,
                    valueColor: Colors.white,
                    fontSize: context.responsiveFont(14),
                  ),
                  const SizedBox(height: 6),
                  InfoRow(
                    label: 'Limite atual (restante)',
                    value: 'R\$ ${data.remainingLimit.toStringAsFixed(2)}',
                    labelColor: Colors.white70,
                    valueColor: Colors.white,
                    fontSize: context.responsiveFont(14),
                  ),
                  const SizedBox(height: 6),
                  InfoRow(
                    label: 'Valor mínimo',
                    value: 'R\$ ${data.absoluteMinLimit.toStringAsFixed(2)}',
                    labelColor: Colors.white70,
                    valueColor: Colors.white,
                    fontSize: context.responsiveFont(14),
                  ),
                ],
              ),
          error:
              (error, stackTrace) => Column(
                children: [
                  InfoRow(
                    label: 'Limite diário',
                    value: 'R\$ 250.00',
                    labelColor: Colors.white70,
                    valueColor: Colors.white,
                    fontSize: context.responsiveFont(14),
                  ),
                  const SizedBox(height: 6),
                  InfoRow(
                    label: 'Valor mínimo',
                    value: 'R\$ 20,00',
                    labelColor: Colors.white70,
                    valueColor: Colors.white,
                    fontSize: context.responsiveFont(14),
                  ),
                ],
              ),
          loading:
              () => Column(
                children: [
                  ShimmerInfoRow(label: "Limite diário"),
                  const SizedBox(height: 6),
                  ShimmerInfoRow(label: "Limite atual"),
                  const SizedBox(height: 6),
                  ShimmerInfoRow(label: "Valor mínimo"),
                ],
              ),
        ),
      ],
    );
  }
}
