import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import '../providers.dart';

import 'account_limits_display_widget.dart';

class PixValueInputWidget extends ConsumerWidget {
  const PixValueInputWidget({super.key});

  static const Color _backgroundColor = Color(0xFF0A0A0A);
  static const Color _cardBackground = Color(0xFF191818);
  static const Color _primaryColor = Color(0xFFEA1E63);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9194A6);
  static const Color _textTertiary = Color(0xFF8E8E8E);
  static const Color _positiveColor = Colors.green;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowedDepositAmount = ref.watch(amountLimitProvider);
    return Container(
      height: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: _buildContainerDecoration(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Valor do PIX',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsiveFont(20),
                  fontWeight: FontWeight.w500
              )
          ),
          PixDepositAmountInput(),
          AccountLimitsDisplay(),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: _cardBackground,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.primary,
          blurRadius: 10,
          spreadRadius: 0,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

class PixDepositAmountInput extends ConsumerWidget {
  final TextEditingController controller = TextEditingController();

  PixDepositAmountInput({super.key});

  @override
  void dispose() {
    controller.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositAmountInput = ref.read(depositAmountProvider.notifier);
    return TextField(
        controller: controller,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: context.responsiveFont(36),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'R\$ 00,00',
          hintStyle: TextStyle(
            color: Colors.white38,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          CurrencyInputFormatter()
        ],
        onChanged: (val) {
          String cleanValue = val.replaceAll('R\$ ', '').replaceAll(',', '.');
          depositAmountInput.state = double.tryParse(cleanValue) ?? 0.0;
        }
    );
  }
}
