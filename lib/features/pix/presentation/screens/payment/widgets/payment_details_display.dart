import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/domain/entities.dart';
import 'package:mooze_mobile/features/pix/presentation/providers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

const minimumAmountForVariableFee = 55 * 100;

class PaymentDetailsDisplay extends ConsumerWidget {
  final PixDeposit deposit;

  const PaymentDetailsDisplay({super.key, required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositAmountInReais = deposit.amountInCents.toDouble() / 100;
    final assetQuote = ref.read(assetQuoteProvider(deposit.asset).future);
    final feeRate = ref.read(feeRateProvider(depositAmountInReais).future);
    final discountedAmount = ref.read(
      discountedFeesDepositProvider(depositAmountInReais).future,
    );
    final assetQuantity = discountedAmount.then(
      (amount) => _getAssetQuantity(assetQuote, amount, deposit.asset),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pinBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildAssetInfo(deposit.asset, assetQuantity, depositAmountInReais),
            Divider(color: Colors.white24, thickness: 1),
            _buildFeeBreakdown(
              context,
              depositAmountInReais,
              feeRate,
              deposit.amountInCents,
            ),
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
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildAssetInfo(
    Asset asset,
    Future<String> assetQuantity,
    double reaisAmount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<String>(
          future: assetQuantity,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 18,
                child: Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              );
            }
            return const Text(
              'N/A',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          'de R\$ ${reaisAmount.toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeBreakdown(
    BuildContext context,
    double depositAmountInReais,
    Future<double> feeRate,
    int amountInCents,
  ) {
    final isFixedFee = amountInCents < minimumAmountForVariableFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taxas aplicadas',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Taxa principal
        if (isFixedFee) ...[
          InfoRow(label: 'Taxa fixa', value: 'R\$ 1,00'),
        ] else ...[
          FutureBuilder<double>(
            future: feeRate,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final feeAmount = depositAmountInReais * (snapshot.data! / 100);
                return InfoRow(
                  label: 'Taxa Mooze',
                  value:
                      'R\$ ${feeAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerInfoRow(label: 'Taxa Mooze');
              }
              return const InfoRow(label: 'Taxa Mooze', value: 'N/A');
            },
          ),
        ],

        const SizedBox(height: 6),

        const InfoRow(label: 'Taxa da processadora', value: 'R\$ 1,00'),
      ],
    );
  }
}

Future<String> _getAssetQuantity(
  Future<Either<String, Option<double>>> futureEitherOptionQuote,
  double amountAfterFees,
  Asset asset,
) {
  return futureEitherOptionQuote.then(
    (x) => x.fold(
      (err) => "N/A",
      (optionQuote) => optionQuote.fold(() => "N/A", (quote) {
        final quantity = amountAfterFees / quote;
        final decimalPlaces = asset == Asset.depix ? 2 : 8;
        return "${quantity.toStringAsFixed(decimalPlaces)} ${asset.ticker.toUpperCase()}";
      }),
    ),
  );
}
