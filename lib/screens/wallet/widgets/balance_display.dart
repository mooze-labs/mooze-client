import 'package:flutter/material.dart';

class BalanceDisplay extends StatelessWidget {
  final int totalSats; // amount in satoshi
  final double btcPriceBrl;
  final bool isBalanceVisible;

  const BalanceDisplay({
    Key? key,
    required this.totalSats,
    required this.isBalanceVisible,
    this.btcPriceBrl = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Computed total in BRL
    final totalBtc = totalSats / 100000000.0;
    final totalBrl = totalBtc * btcPriceBrl; // convert to BTC

    // Show/Hide logic
    final displayBtc =
        isBalanceVisible ? "${totalBtc.toStringAsFixed(8)} BTC" : "•••• BTC";
    final displayBrl =
        isBalanceVisible ? "R\$ ${totalBrl.toStringAsFixed(2)}" : "R\$ ••••";

    return SizedBox(
      height: 200,

      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E1E1E), // dark
                      Color(0xFFD973C1), // pink
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Saldo",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  displayBtc,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayBrl,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorBalanceDisplay extends StatelessWidget {
  final String error;

  const ErrorBalanceDisplay({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayBtc = "Error: $error";
    final displayBrl = "Error";

    return SizedBox(
      height: 200,

      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E1E1E), // dark
                      Color(0xFFD973C1), // pink
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Saldo",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  displayBtc,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayBrl,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
