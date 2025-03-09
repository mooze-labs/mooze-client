import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/data/asset_data.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/utils/fees.dart';

class TransactionInfo extends ConsumerWidget {
  final String assetId;
  final String address;
  final int amount;

  TransactionInfo({
    super.key,
    required this.assetId,
    required this.address,
    required this.amount,
  });

  Widget _buildTransactionDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: "roboto",
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontFamily: "roboto", fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fiatPrices = ref.watch(fiatPricesProvider);
    final assetInfo = knownLiquidAssets[assetId];

    return fiatPrices.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text("Erro ao gerar pagamento, tente novamente."),
      data: (data) {
        final fiatPrice = data[assetInfo!.fiatPriceId];
        final feeRate =
            FeeCalculator(assetId: assetId, fiatAmount: amount).getFees();

        final assetAmount = amount / fiatPrice!;
        final fees = (assetAmount * feeRate);
        final amountToReceive = assetAmount - fees;

        print("[DEBUG] Got fiat prices.");
        print(["[DEBUG] Asset: $assetId, Asset info: $assetInfo"]);
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildTransactionDetailRow(
                "Valor",
                "R\$ ${amount.toStringAsFixed(2)}",
              ),
              _buildTransactionDetailRow("Cotação", "$fiatPrice"),
              _buildTransactionDetailRow(
                "Quantidade",
                "${amountToReceive.toStringAsFixed(assetInfo.precision)} ${assetInfo.ticker}",
              ),
              _buildTransactionDetailRow(
                "Taxa",
                "${fees.toStringAsFixed(assetInfo.precision)} ${assetInfo.ticker}",
              ),
              _buildTransactionDetailRow(
                "Endereço",
                "${address.substring(0, 5)}...${address.substring(address.length - 5)}",
              ),
            ],
          ),
        );
      },
    );
  }
}
