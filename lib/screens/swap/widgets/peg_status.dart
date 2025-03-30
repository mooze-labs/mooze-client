import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/models/sideswap.dart';

class PegStatus extends StatelessWidget {
  final PegTransaction pegTransaction;

  const PegStatus({super.key, required this.pegTransaction});

  String _getStatusInPortuguese(TxState txState) {
    switch (txState) {
      case TxState.insufficientAmount:
        return "Valor insuficiente";
      case TxState.processing:
        return "Processando";
      case TxState.detected:
        return "Depósito detectado";
      case TxState.done:
        return "Concluído";
      case TxState.unknown:
        return "Desconhecido";
    }
  }

  Widget _buildDetailRow(String label, String value) {
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
            style: TextStyle(
              fontFamily: "roboto",
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTxDisplay(
    BuildContext context,
    Map<String, dynamic> pegDetails,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ...pegDetails.entries.map(
            (entry) => _buildDetailRow(entry.key, entry.value.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildTx(BuildContext context, PegTransaction pegTransaction) {
    final Map<String, dynamic> txDetails = {
      "TXID":
          "${pegTransaction.txHash.substring(0, 5)}...${pegTransaction.txHash.substring(pegTransaction.txHash.length - 5)}",
      "Status": _getStatusInPortuguese(pegTransaction.txState),
      "Qtd. enviada": (pegTransaction.amount / pow(10, 8)).toStringAsFixed(8),
      "Payout":
          (pegTransaction.payout != null)
              ? ((pegTransaction.payout! / pow(10, 8)).toStringAsFixed(8))
              : "N/A",
      "Confirmações": pegTransaction.status.toString(),
      "TXID Payout":
          (pegTransaction.payoutTxid != null)
              ? "${pegTransaction.payoutTxid!.substring(0, 5)}...${pegTransaction.payoutTxid!.substring(pegTransaction.payoutTxid!.length - 5)}"
              : "N/A",
    };

    return _buildTxDisplay(context, txDetails);
  }

  @override
  Widget build(BuildContext context) {
    return _buildTx(context, pegTransaction);
  }
}
