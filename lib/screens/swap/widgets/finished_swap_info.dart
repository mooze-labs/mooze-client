import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/models/assets.dart';

class FinishedSwapInfo extends StatelessWidget {
  final Asset sentAsset;
  final Asset receivedAsset;
  final int sentAmount;
  final int receivedAmount;
  final int fees;

  const FinishedSwapInfo({
    required this.sentAsset,
    required this.receivedAsset,
    required this.sentAmount,
    required this.receivedAmount,
    required this.fees,
    super.key,
  });

  Widget _buildSwapDetailRow(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Enviado",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          _buildSwapDetailRow(
            "Enviado",
            "${(sentAmount / pow(10, sentAsset.precision)).toStringAsFixed(sentAsset.precision)} ${sentAsset.ticker}",
          ),
          _buildSwapDetailRow(
            "Recebido",
            "${(receivedAmount / pow(10, receivedAsset.precision)).toStringAsFixed(receivedAsset.precision)} ${receivedAsset.ticker}",
          ),
          // _buildSwapDetailRow("Taxas", "$fees sats"),
        ],
      ),
    );
  }
}
