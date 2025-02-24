import 'package:flutter/material.dart';

class ModernBalanceDisplay extends StatelessWidget {
  final double totalBtc;
  final double btcPriceBrl;
  final bool isBalanceVisible;

  const ModernBalanceDisplay({
    Key? key,
    required this.totalBtc,
    required this.btcPriceBrl,
    required this.isBalanceVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Computed total in BRL
    final totalBrl = totalBtc * btcPriceBrl;

    // Show/Hide logic
    final displayBtc = isBalanceVisible
        ? "${totalBtc.toStringAsFixed(8)} BTC"
        : "•••• BTC";
    final displayBrl = isBalanceVisible
        ? "R\$ ${totalBrl.toStringAsFixed(2)}"
        : "R\$ ••••";

    return SizedBox(
      // Takes some vertical space (adjust to your taste)
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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A custom clipper that creates a simple diagonal shape
class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.7);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_DiagonalClipper oldClipper) => false;
}
