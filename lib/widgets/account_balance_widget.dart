import 'package:flutter/material.dart';

class AccountBalanceWidget extends StatelessWidget {
  final double btcBalance;       // The user's BTC balance
  final double brlEquivalent;    // The user's BRL equivalent (converted)
  final bool isBalanceVisible;   // Whether the balances should be shown or hidden

  const AccountBalanceWidget({
    Key? key,
    required this.btcBalance,
    required this.brlEquivalent,
    required this.isBalanceVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format values or hide them based on isBalanceVisible
    final displayBtc = isBalanceVisible
        ? "${btcBalance.toStringAsFixed(8)} BTC"
        : "•••• BTC";

    final displayBrl = isBalanceVisible
        ? "R\$ ${brlEquivalent.toStringAsFixed(2)}"
        : "R\$ ••••";

    return Container(
      // A container with a slightly lighter background and a pink border
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD973C1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading or label
          const Text(
            "Saldo em Bitcoin",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Large BTC balance
          Text(
            displayBtc,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Smaller, secondary text for BRL amount
          Text(
            displayBrl,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
