import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/user/providers/values_to_receive_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_total_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class ValuesToReceiveCard extends ConsumerStatefulWidget {
  const ValuesToReceiveCard({super.key});

  @override
  ConsumerState<ValuesToReceiveCard> createState() =>
      _ValuesToReceiveCardState();
}

class _ValuesToReceiveCardState extends ConsumerState<ValuesToReceiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valuesToReceiveAsync = ref.watch(valuesToReceiveProvider);
    final totalValueAsync = ref.watch(totalValueToReceiveProvider);
    final currentBalanceAsync = ref.watch(totalWalletValueProvider);
    final currencyIcon = ref.watch(currencyControllerProvider.notifier).icon;

    return valuesToReceiveAsync.when(
      data:
          (result) => result.fold((error) => const SizedBox.shrink(), (
            toReceiveList,
          ) {
            if (toReceiveList.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFF1C1F24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com ícone animado e informações
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Ícone animado
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: context.colors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RotationTransition(
                          turns: _rotationAnimation,
                          child: Icon(
                            Icons.sync,
                            color: context.colors.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Coluna com texto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pagamentos em análise',
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            totalValueAsync.when(
                              data:
                                  (total) => Text(
                                    'Total: $currencyIcon ${total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: context.colors.primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              loading:
                                  () => Text(
                                    'Calculando...',
                                    style: TextStyle(
                                      color: context.colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              error: (_, _) => SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,
                      color: context.colors.textSecondary.withValues(alpha: 0.1),
                    ),
                  ),

                  // Lista de assets
                  ...toReceiveList.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            item.asset.iconPath,
                            width: 20,
                            height: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.asset.name,
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Text(
                            item.formattedValue,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      loading: () => const SizedBox.shrink(),

      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
