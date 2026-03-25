import 'package:flutter/material.dart';

/// Merchant Header Widget (Presentation Layer)
///
/// Header component for the merchant mode screen displaying:
/// - Back button to exit merchant mode
/// - Title "Merchant Mode"
/// - Current cart total in BRL (R$)
/// - "Clear cart" button (only visible when cart has items)

class MerchantHeaderWidget extends StatelessWidget {
  /// Current total value in BRL (Brazilian Real)
  final double totalAmountInBRL;
  final VoidCallback onClearCart;
  final VoidCallback? onBack;
  final GlobalKey? clearButtonKey;
  final GlobalKey? totalAmountKey;

  const MerchantHeaderWidget({
    super.key,
    required this.totalAmountInBRL,
    required this.onClearCart,
    this.onBack,
    this.clearButtonKey,
    this.totalAmountKey,
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
          key: totalAmountKey,
          child: Text(
            'R\$${totalAmountInBRL.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (totalAmountInBRL > 0) ...[
          SizedBox(height: 4),
          GestureDetector(
            key: clearButtonKey,
            onTap: onClearCart,
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
