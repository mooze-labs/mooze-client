import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/domain/entities.dart';
import 'package:mooze_mobile/features/pix/presentation/providers.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/payment/consts.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';

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
      padding: const EdgeInsets.symmetric(
        horizontal: containerPadding,
        vertical: containerVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [BoxShadow(color: Color(0x4DEA1E63), blurRadius: 8)],
      ),
      child: Column(
        children: [
          InfoRow(
            label: "Valor",
            value: "R\$ ${(deposit.amountInCents.toDouble() / 100)}",
          ),
          _buildAssetQuote(_getAssetQuote(assetQuote)),
          _buildAssetQuantity(assetQuantity),
          _buildFeeRateDisplay(feeRate, deposit.amountInCents),
        ],
      ),
    );
  }

  Widget _buildFeeRateDisplay(Future<double> rate, int amountInCents) {
    if (amountInCents < minimumAmountForVariableFee)
      return InfoRow(label: "Taxa", value: "R\$ 2.00 + rede");

    return FutureBuilder(
      future: rate,
      builder: (context, snapshot) {
        if (snapshot.hasData)
          return InfoRow(
            label: "Taxa",
            value: snapshot.data!.toStringAsFixed(2),
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return ShimmerInfoRow(label: "Taxa");

        return InfoRow(label: "Taxa", value: "N/A");
      },
    );
  }

  Widget _buildAssetQuote(Future<String> quote) {
    return FutureBuilder(
      future: quote,
      builder: (context, snapshot) {
        if (snapshot.hasData)
          return InfoRow(label: "Cotação", value: snapshot.data!);
        if (snapshot.connectionState == ConnectionState.waiting)
          return ShimmerInfoRow(label: "Quantidade");

        return InfoRow(label: "Quantidade", value: "N/A");
      },
    );
  }

  Widget _buildAssetQuantity(Future<String> quantity) {
    return FutureBuilder(
      future: quantity,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return InfoRow(label: "Quantidade", value: snapshot.data!);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerInfoRow(label: "Quantidade");
        }

        return InfoRow(label: "Quantidade", value: "N/A");
      },
    );
  }
}

Future<String> _getAssetQuote(
  Future<Either<String, Option<double>>> futureEitherOptionQuote,
) {
  return futureEitherOptionQuote.then(
    (x) => x.fold(
      (err) {
        if (kDebugMode) debugPrint("Failed to get quote: $err");
        return "N/A";
      },
      (optionQuote) =>
          optionQuote.fold(() => "N/A", (quote) => quote.toStringAsFixed(2)),
    ),
  );
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
        (quote) => "${(amountAfterFees / quote)} ${asset.ticker.toUpperCase()}",
      ),
    ),
  );
}
