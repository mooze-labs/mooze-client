import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/exceptions/user_friendly_exception.dart';

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
            value: 'Ver níveis',
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
                    value:
                        'R\$ ${UserLevelsData.dailyLimit.toStringAsFixed(2)}',
                    labelColor: Colors.white70,
                    valueColor: Colors.white,
                    fontSize: context.responsiveFont(14),
                  ),
                  const SizedBox(height: 6),
                  InfoRow(
                    label: 'Por transação',
                    value: 'R\$ ${data.allowedSpending.toStringAsFixed(2)}',
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
                    value:
                        'R\$ ${UserLevelsData.dailyLimit.toStringAsFixed(2)}',
                    labelColor: Colors.white70,
                    valueColor: Colors.white,
                    fontSize: context.responsiveFont(14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Erro ao carregar limites',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: context.responsiveFont(13),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ref.invalidate(levelsProvider);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tentar novamente',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: context.responsiveFont(12),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: context.responsiveFont(12),
                          ),
                        ),
                        if (error is UserFriendlyException &&
                            error.getTechnicalMessage() != null &&
                            kDebugMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Detalhes: ${error.getTechnicalMessage()}',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: context.responsiveFont(11),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          loading:
              () => Column(
                children: [
                  ShimmerInfoRow(label: "Limite diário"),
                  const SizedBox(height: 6),
                  ShimmerInfoRow(label: "Por transação"),
                  const SizedBox(height: 6),
                  ShimmerInfoRow(label: "Valor mínimo"),
                ],
              ),
        ),
      ],
    );
  }
}
