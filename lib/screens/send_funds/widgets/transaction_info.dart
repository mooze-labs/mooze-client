import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:lwk/lwk.dart' as lwk;
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';

class TransactionInfo extends StatelessWidget {
  final Asset asset;
  final String address;
  final int amount;
  final int feeRate;

  TransactionInfo({
    required this.asset,
    required this.address,
    required this.amount,
    required this.feeRate,
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
  Widget build(BuildContext context) {
    final networkName =
        (asset.network == Network.liquid) ? "Liquid Network" : "Bitcoin";

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTransactionDetailRow("Ativo", asset.name),
          _buildTransactionDetailRow(
            "Endereço",
            "${address.substring(0, 10)}...${address.substring(address.length - 10)}",
          ),
          _buildTransactionDetailRow(
            "Quantidade",
            "${(amount / pow(10, asset.precision)).toStringAsFixed(asset.precision)} ${asset.ticker}",
          ),
          _buildTransactionDetailRow(
            "Taxa",
            "${(feeRate / pow(10, 8)).toStringAsFixed(8)} ${asset.ticker}",
          ),
          _buildTransactionDetailRow("Rede", networkName),
        ],
      ),
    );
  }
}
