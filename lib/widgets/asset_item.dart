import 'package:flutter/material.dart';

class AssetItem extends StatelessWidget {
  final String assetName;
  final String assetIconPath;
  final String balance;
  final bool isBalanceVisible;

  const AssetItem({
    Key? key,
    required this.assetName,
    required this.assetIconPath,
    required this.balance,
    required this.isBalanceVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayBalance = isBalanceVisible ? balance : "••••";

    return Container(
      width: double.infinity, // Fill parent width
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD973C1),
          width: 1,
        ),
      ),
      // We rely on ListTile for consistent internal padding
      child: ListTile(
        // Default ListTile horizontal padding is 16. 
        // You can override with contentPadding if you want exact control:
        // contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Image.asset(
          assetIconPath,
          width: 40,
          height: 40,
        ),
        title: Text(
          assetName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Saldo: $displayBalance",
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
