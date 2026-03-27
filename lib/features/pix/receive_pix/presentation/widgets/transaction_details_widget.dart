import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/referral_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/selected_asset_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

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

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.baseColor,
      highlightColor: context.colors.highlightColor,
      child: Container(
        width: 30,
        height: 10,
        decoration: BoxDecoration(
          color: context.colors.baseColor,
          borderRadius: BorderRadius.circular(4),
        ),
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
        if (kDebugMode) debugPrint(error.toString());
        return _returnError(context);
      },
      data: (data) => data.fold(
        (error) {
          if (kDebugMode) debugPrint(error.toString());
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              );
            },
            error: (error, stackTrace) {
              if (kDebugMode) debugPrint(error.toString());
              return _returnError(context);
            },
            loading: () => _buildShimmer(context),
          ),
        ),
      ),
      loading: () => _buildShimmer(context),
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
      decoration: _buildContainerDecoration(context),
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
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildReaisAmount(BuildContext context, double amount) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Text(
      'de R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: onSurface.withValues(alpha: 0.5),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taxas aplicadas',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: onSurface.withValues(alpha: 0.7),
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
            data: (amount) => hasReferral.when(
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
              error: (_, _) => _buildSimpleFeeCard(
                context,
                title: 'Taxa Mooze',
                value: 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                subtitle: null,
                percent: '2,32%',
                icon: Icons.receipt_long,
              ),
              loading: () => _buildSimpleFeeCard(
                context,
                title: 'Taxa Mooze',
                value: '...',
                percent: '...%',
                subtitle: null,
                icon: Icons.receipt_long,
              ),
            ),
            error: (_, _) => _buildSimpleFeeCard(
              context,
              title: 'Taxa Mooze',
              value: 'Erro',
              percent: '...%',
              subtitle: null,
              icon: Icons.receipt_long,
            ),
            loading: () => _buildSimpleFeeCard(
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    color: onSurface.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
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
                style: textTheme.bodyMedium?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              percent != null && percent.isNotEmpty
                  ? Text(
                    percent,
                    style: textTheme.labelMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
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
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration, size: 16, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onSurface.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 40, color: onSurface.withValues(alpha: 0.3)),
          SizedBox(height: 12),
          Text(
            'Aguardando valor',
            style: textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Digite um valor válido para ver\no resumo da transação',
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
              color: onSurface.withValues(alpha: 0.4),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: context.colors.surfaceLow,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
