import 'package:flutter/material.dart';

class MerchantHeaderWidget extends StatelessWidget {
  final double valorReais;
  final VoidCallback onLimparCarrinho;
  final VoidCallback? onBack;
  final GlobalKey? limparButtonKey;
  final GlobalKey? valorTotalKey;

  const MerchantHeaderWidget({
    super.key,
    required this.valorReais,
    required this.onLimparCarrinho,
    this.onBack,
    this.limparButtonKey,
    this.valorTotalKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onBack,
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
            SizedBox(width: 48),
          ],
        ),
        SizedBox(height: 10),
        Container(
          key: valorTotalKey,
          child: Text(
            'R\$${valorReais.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (valorReais > 0) ...[
          SizedBox(height: 4),
          GestureDetector(
            key: limparButtonKey,
            onTap: onLimparCarrinho,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade600.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade400, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Limpar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
