import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';

class PegDetails extends StatelessWidget {
  final String orderId;
  final bool pegIn;
  final int minAmount;
  final String destinationAddress;

  const PegDetails({
    super.key,
    required this.orderId,
    required this.pegIn,
    required this.minAmount,
    required this.destinationAddress,
  });

  Widget _buildDisplayRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: "roboto",
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: "roboto",
            fontSize: 16,
            color: Theme.of(context).colorScheme.onPrimary,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String sendAssetTicker = (pegIn) ? "BTC" : "L-BTC";

    return Container(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDisplayRow(context, "Taxa de conversão", "0.1%"),
                Column(
                  children: [
                    _buildDisplayRow(
                      context,
                      "Id da transação",
                      "${orderId.substring(0, 5)}...${orderId.substring(orderId.length - 5)}",
                    ),
                    _buildDisplayRow(
                      context,
                      "Valor mínimo",
                      "${(minAmount / pow(10, 8)).toStringAsFixed(8)} $sendAssetTicker",
                    ),
                    _buildDisplayRow(
                      context,
                      "Endereço de destino",
                      "${destinationAddress.substring(0, 5)}...${destinationAddress.substring(destinationAddress.length - 5)}",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
