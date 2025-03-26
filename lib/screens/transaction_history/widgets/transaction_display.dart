import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionDisplay extends StatelessWidget {
  final TransactionRecord transaction;

  TransactionDisplay({super.key, required this.transaction});

  String _formatBalance() {
    if (transaction.asset.precision == 0) return "${transaction.amount}".trim();

    final double value =
        transaction.amount / pow(10, transaction.asset.precision);

    return "${value.toStringAsFixed(transaction.asset.precision)} ${transaction.asset.ticker}";
  }

  String _formatTimestamp() {
    if (transaction.timestamp == null) return "";
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.timestamp!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          transaction.direction == TransactionDirection.incoming
              ? Icon(Icons.call_received, size: 40)
              : Icon(Icons.arrow_outward, size: 40),
          const SizedBox.square(dimension: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatBalance(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: "roboto",
                  ),
                ),
                Text(
                  _formatTimestamp(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: "roboto",
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            child: Icon(Icons.travel_explore, size: 30, color: Theme.of(context).colorScheme.primary),
            onTap: () {
              if (transaction.network == Network.liquid) {
                launchUrl(
                  Uri.parse('https://liquid.network/pt/tx/${transaction.txid}'),
                );
                return;
              } else {
                launchUrl(
                  Uri.parse("https://mempool.space/tx/${transaction.txid}"),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
