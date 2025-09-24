import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MerchantHeaderWidget extends StatelessWidget {
  final double valorReais;
  final double valorBitcoin;

  const MerchantHeaderWidget({
    super.key,
    required this.valorReais,
    required this.valorBitcoin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                context.pop();
              },
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            Text(
              'Modo comerciante',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.download, color: Colors.white, size: 24),
          ],
        ),
        SizedBox(height: 20),
        Text(
          'R\$${valorReais.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '${valorBitcoin.toStringAsFixed(6)} BTC',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
        ),
      ],
    );
  }
}
