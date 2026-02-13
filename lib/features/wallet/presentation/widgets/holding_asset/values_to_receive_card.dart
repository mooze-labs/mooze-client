import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/user/providers/values_to_receive_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_total_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/values_to_receive_display_mode_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

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
    final displayMode = ref.watch(valuesToReceiveDisplayModeProvider);
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
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RotationTransition(
                          turns: _rotationAnimation,
                          child: Icon(
                            Icons.sync,
                            color: AppColors.primaryColor,
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
                              'Valores a Receber',
                              style: TextStyle(
                                color: AppColors.textPrimary,
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
                                      color: AppColors.primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              loading:
                                  () => Text(
                                    'Calculando...',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      // Botão para alternar entre native/fiat
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(valuesToReceiveDisplayModeProvider.notifier)
                              .state = displayMode.toggle;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            displayMode == ValuesToReceiveDisplayMode.fiat
                                ? Icons.currency_bitcoin
                                : Icons.attach_money,
                            color: AppColors.primaryColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.asset.name,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Text(
                            displayMode == ValuesToReceiveDisplayMode.fiat
                                ? item.formattedValueInFiat
                                : item.formattedValue,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Previsão de saldo após recebimento
                  if (totalValueAsync.hasValue && currentBalanceAsync.hasValue)
                    currentBalanceAsync.when(
                      data:
                          (balanceResult) => balanceResult.fold(
                            (error) => const SizedBox.shrink(),
                            (currentBalance) => totalValueAsync.when(
                              data: (pendingTotal) {
                                final futureBalance =
                                    currentBalance + pendingTotal;
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        color: AppColors.primaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Saldo após recebimento',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$currencyIcon ${futureBalance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
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
