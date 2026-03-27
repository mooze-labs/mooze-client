import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/exceptions/user_friendly_exception.dart';

import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

class AccountLimitsDisplay extends ConsumerWidget {
  final VoidCallback? onToggleView;

  const AccountLimitsDisplay({super.key, this.onToggleView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsData = ref.watch(levelsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: onToggleView,
          child: InfoRow(
            label: 'Meus limites',
            value: 'Ver níveis',
            labelColor: onSurface,
            valueColor: context.colors.primaryColor,
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
                    labelColor: onSurface.withValues(alpha: 0.7),
                    valueColor: onSurface,
                    fontSize: context.responsiveFont(14),
                  ),
                  const SizedBox(height: 6),
                  InfoRow(
                    label: 'Por transação',
                    value: 'R\$ ${data.allowedSpending.toStringAsFixed(2)}',
                    labelColor: onSurface.withValues(alpha: 0.7),
                    valueColor: onSurface,
                    fontSize: context.responsiveFont(14),
                  ),
                  SizedBox(height: 6),
                  InfoRow(
                    label: 'Valor mínimo',
                    value: 'R\$ ${data.absoluteMinLimit.toStringAsFixed(2)}',
                    labelColor: onSurface.withValues(alpha: 0.7),
                    valueColor: onSurface,
                    fontSize: context.responsiveFont(14),
                  ),
                ],
              ),
          error: (error, stackTrace) {
            final warning = context.appColors.warning;
            return Column(
              children: [
                InfoRow(
                  label: 'Limite diário',
                  value: 'R\$ ${UserLevelsData.dailyLimit.toStringAsFixed(2)}',
                  labelColor: onSurface.withValues(alpha: 0.7),
                  valueColor: onSurface,
                  fontSize: context.responsiveFont(14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: warning.withValues(alpha: 0.3),
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
                            color: warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Erro ao carregar limites',
                              style: textTheme.labelLarge?.copyWith(
                                color: warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref.invalidate(levelsProvider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: warning,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tentar novamente',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onPrimary,
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
                        style: textTheme.labelMedium?.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (error is UserFriendlyException &&
                          error.getTechnicalMessage() != null &&
                          kDebugMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Detalhes: ${error.getTechnicalMessage()}',
                            style: textTheme.labelSmall?.copyWith(
                              color: onSurface.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
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
