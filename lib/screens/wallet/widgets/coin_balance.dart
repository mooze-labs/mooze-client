import 'dart:math';
import 'dart:ui';
import "package:flutter/material.dart";

class CoinBalance extends StatelessWidget {
  final String name;
  final int amount; // in sats
  final String unitName; // e.g. satoshi, btc, wei, eth, depix, etc.
  final int precision; // number of decimal places for formatting
  final bool isBalanceVisible; // toggle to show/hide amount
  final Widget logo;

  CoinBalance({
    required this.name,
    required this.amount,
    required this.unitName,
    required this.precision,
    required this.logo,
    this.isBalanceVisible = true,
  });

  String _formatBalance() {
    if (!isBalanceVisible) return "••••";
    if (precision == 0) return "$amount $unitName".trim();

    final double value = amount / (pow(10, precision));
    return "$value $unitName".trim();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 40, height: 40, child: logo),
        SizedBox.square(dimension: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatBalance(),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }
}

class LoadingCoinBalance extends StatelessWidget {
  final int amount;
  final bool isBalanceVisible;

  const LoadingCoinBalance({
    required this.amount,
    this.isBalanceVisible = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CoinBalance(
      name: "Carregando...",
      amount: 0,
      unitName: "N/A",
      precision: 0,
      logo: const CircularProgressIndicator(),
      isBalanceVisible: isBalanceVisible,
    );
  }
}

class ErrorCoinBalance extends StatelessWidget {
  final String error;
  final int amount;
  final bool isBalanceVisible;

  const ErrorCoinBalance({
    required this.error,
    required this.amount,
    this.isBalanceVisible = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CoinBalance(
      name: "Erro: $error",
      amount: amount,
      unitName: "N/A",
      precision: 0,
      logo: Image.asset("assets/default-coin-logo.png"),
      isBalanceVisible: isBalanceVisible,
    );
  }
}

class CoinBalanceList extends StatelessWidget {
  final List<Widget> coinBalances;

  const CoinBalanceList({required this.coinBalances});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFD973C1)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            coinBalances
                .map(
                  (coin) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: coin,
                  ),
                )
                .toList(),
      ),
    );
  }
}
