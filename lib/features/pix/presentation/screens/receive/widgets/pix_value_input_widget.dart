import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import '../providers.dart';

import 'pix_deposit_amount_input.dart';
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