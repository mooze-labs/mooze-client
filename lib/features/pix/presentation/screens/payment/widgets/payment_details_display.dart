import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAssetInfo(deposit.asset, assetQuantity),
            const Divider(color: Colors.white24, thickness: 1),
            _buildFeeDetails(
              context,
              depositAmountInReais,
              feeRate,
              deposit.amountInCents,
              discountedAmount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetInfo(Asset asset, Future<String> assetQuantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAssetLabel(asset),
          FutureBuilder<String>(
            future: assetQuantity,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  snapshot.data!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 80,
                  height: 16,
                  child: Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssetLabel(Asset asset) {
    return Row(
      children: [
        SvgPicture.asset(asset.iconPath, width: 24, height: 24),
        const SizedBox(width: 10),
        Text(
          asset.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeDetails(
    BuildContext context,
    double depositAmountInReais,
    Future<double> feeRate,
    int amountInCents,
    Future<double> discountedAmount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          InfoRow(
            label: "Valor a pagar (via PIX)",
            value: "R\$ ${depositAmountInReais.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 6),
          _buildFeeRateDisplay(feeRate, amountInCents),
          const SizedBox(height: 6),
          const InfoRow(label: "Taxa da processadora", value: "R\$ 1.00"),
          const SizedBox(height: 6),
          FutureBuilder<double>(
            future: discountedAmount,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return InfoRow(
                  label: "Saldo creditado",
                  value: "R\$ ${snapshot.data!.toStringAsFixed(2)}",
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerInfoRow(label: "Valor final");
              }
              return const InfoRow(label: "Valor final", value: "Erro");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRateDisplay(Future<double> rate, int amountInCents) {
    if (amountInCents < minimumAmountForVariableFee) {
      return const InfoRow(label: "Taxa Mooze", value: "R\$ 1.00 + rede");
    }

    return FutureBuilder(
      future: rate,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return InfoRow(
            label: "Taxa da plataforma",
            value: "${snapshot.data!.toStringAsFixed(2)}%",
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerInfoRow(label: "Taxa da plataforma");
        }

        return const InfoRow(label: "Taxa da plataforma", value: "N/A");
      },
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
      (optionQuote) => optionQuote.fold(
        () => "N/A",
        (quote) =>
            "${(amountAfterFees / quote).toStringAsFixed(8)} ${asset.ticker.toUpperCase()}",
      ),
    ),
  );
}
