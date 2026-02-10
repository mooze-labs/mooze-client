import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers.dart';

class AssetAmountDisplay extends ConsumerWidget {
  const AssetAmountDisplay({super.key});

  Widget _returnError(BuildContext context) {
    return Text(
      "N/A",
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final depositAmount = ref.read(depositAmountProvider);
    final assetQuote = ref.watch(assetQuoteProvider(selectedAsset));
    final discountedDepositAmount = ref.watch(
      discountedFeesDepositProvider(depositAmount),
    );

    return assetQuote.when(
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(error.toString());
        }
        return _returnError(context);
      },
      data:
          (data) => data.fold(
            (error) {
              if (kDebugMode) {
                debugPrint(error.toString());
              }
              return _returnError(context);
            },
            (val) => val.fold(
              () => _returnError(context),
              (quote) => discountedDepositAmount.when(
                data: (depositAmount) {
                  final amount = depositAmount / quote;
                  final decimalPlaces = selectedAsset == Asset.depix ? 2 : 8;
                  return Text(
                    amount.toStringAsFixed(decimalPlaces),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  );
                },
                error: (error, stackTrace) {
                  if (kDebugMode) {
                    debugPrint(error.toString());
                  }
                  return _returnError(context);
                },
                loading:
                    () => Shimmer.fromColors(
                      baseColor: Colors.grey[800]!,
                      highlightColor: Colors.grey[600]!,
                      child: Container(
                        width: 30,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
              ),
            ),
          ),
      loading:
          () => Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(
              width: 30,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
    );
  }
}

class TransactionDisplayWidget extends ConsumerWidget {
  const TransactionDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final depositAmount = ref.watch(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);

    return Container(
      decoration: _buildContainerDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (validation.isValid) ...[
              _buildHeader(context),
              _buildAssetAmount(context, selectedAsset, ref),
              _buildReaisAmount(context, depositAmount),
              const SizedBox(height: 10),
              _buildFeeBreakdown(context, ref, depositAmount),
            ] else ...[
              _buildEmptyState(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Você receberá',
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildAssetAmount(BuildContext context, Asset asset, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AssetAmountDisplay(),
        const SizedBox(width: 8),
        Text(
          asset.ticker,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildReaisAmount(BuildContext context, double amount) {
    return Text(
      'de R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildFeeBreakdown(
    BuildContext context,
    WidgetRef ref,
    double depositAmount,
  ) {
    final feeAmount = ref.watch(feeAmountProvider(depositAmount));
    final hasReferral = ref.watch(hasReferralProvider);
    final isFixedFee = depositAmount <= fixedFeeRateThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taxas aplicadas',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        if (isFixedFee) ...[
          _buildSimpleFeeCard(
            context,
            title: 'Taxa fixa (Mooze)',
            value: 'R\$ 1,00',
            subtitle: 'Para valores até R\$ 55',
            icon: Icons.receipt_long,
          ),
        ] else ...[
          feeAmount.when(
            data:
                (amount) => hasReferral.when(
                  data: (hasRef) {
                    if (hasRef) {
                      final originalAmount = amount / 0.85;
                      final savedAmount = originalAmount - amount;

                      return Column(
                        children: [
                          _buildSimpleFeeCard(
                            context,
                            title: 'Taxa Mooze',
                            value:
                                'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                            percent: '2,32%',
                            subtitle: 'Já com 15% de desconto aplicado',
                            icon: Icons.receipt_long,
                          ),
                          const SizedBox(height: 8),
                          _buildDiscountBadge(
                            context,
                            'Você economizou R\$ ${savedAmount.toStringAsFixed(2).replaceAll('.', ',')} com o código de indicação!',
                          ),
                        ],
                      );
                    }
                    return _buildSimpleFeeCard(
                      context,
                      title: 'Taxa Mooze',
                      value:
                          'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                      subtitle: null,
                      percent: '2,32%',
                      icon: Icons.receipt_long,
                    );
                  },
                  error:
                      (_, __) => _buildSimpleFeeCard(
                        context,
                        title: 'Taxa Mooze',
                        value:
                            'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                        subtitle: null,
                        percent: '2,32%',
                        icon: Icons.receipt_long,
                      ),
                  loading:
                      () => _buildSimpleFeeCard(
                        context,
                        title: 'Taxa Mooze',
                        value: '...',
                        percent: '...%',
                        subtitle: null,
                        icon: Icons.receipt_long,
                      ),
                ),
            error:
                (_, __) => _buildSimpleFeeCard(
                  context,
                  title: 'Taxa Mooze',
                  value: 'Erro',
                  percent: '...%',

                  subtitle: null,
                  icon: Icons.receipt_long,
                ),
            loading:
                () => _buildSimpleFeeCard(
                  context,
                  title: 'Taxa Mooze',
                  value: '...',
                  percent: '...%',
                  subtitle: null,
                  icon: Icons.receipt_long,
                ),
          ),
        ],

        const SizedBox(height: 8),

        _buildSimpleFeeCard(
          context,
          title: 'Taxa da processadora',
          value: 'R\$ 1,00',
          subtitle: null,
          icon: Icons.account_balance,
        ),
      ],
    );
  }

  Widget _buildSimpleFeeCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    String? percent,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              percent != null && percent.isNotEmpty
                  ? Text(
                    percent,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration, size: 16, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Aguardando valor',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Digite um valor válido para ver\no resumo da transação',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: AppColors.pinBackground,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
