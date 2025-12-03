import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class FinalizarVendaButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double? cartTotal;
  final GlobalKey? buttonKey;

  const FinalizarVendaButton({
    super.key,
    required this.onPressed,
    this.cartTotal,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallScreen = screenHeight < 650;
    final isSmallScreen = screenHeight < 700 && screenHeight >= 650;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 12 : 16,
      ).copyWith(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: PlatformSafeArea(
        androidTop: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              key: buttonKey,
              text: 'Finalizar Venda',
              onPressed: onPressed,
              isEnabled: cartTotal == null || cartTotal! >= 20.0,
              height: isVerySmallScreen ? 48 : (isSmallScreen ? 52 : 56),
            ),
            if (cartTotal != null && cartTotal! > 0 && cartTotal! < 20.0) ...[
              SizedBox(height: isVerySmallScreen ? 6 : 8),
              Text(
                'Mínimo R\$ 20,00',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
