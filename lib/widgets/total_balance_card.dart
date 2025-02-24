import 'package:flutter/material.dart';

class TotalBalanceCard extends StatelessWidget {
  final double totalBtc;      
  final double btcPriceBrl;
  final bool isBalanceVisible;

  const TotalBalanceCard({
    Key? key,
    required this.totalBtc,
    required this.btcPriceBrl,
    required this.isBalanceVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalBrl = totalBtc * btcPriceBrl;

    final displayBtc = isBalanceVisible 
      ? "${totalBtc.toStringAsFixed(8)} BTC"
      : "•••• BTC";

    final displayBrl = isBalanceVisible
      ? "R\$ ${totalBrl.toStringAsFixed(2)}"
      : "R\$ ••••";

    return Container(
      width: double.infinity,  
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD973C1),
          width: 1,
        ),
      ),
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Saldo Total em Bitcoin",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayBtc,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayBrl,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
