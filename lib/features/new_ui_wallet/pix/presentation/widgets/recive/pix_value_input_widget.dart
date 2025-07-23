import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/extensions/responsive_extensions.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/currency_input_formater.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/info_row.dart';


class PixValueInputWidget extends StatelessWidget {
  final TextEditingController valueController;

  const PixValueInputWidget({
    Key? key,
    required this.valueController,
  }) : super(key: key);

    // Constants - Colors
  static const Color _backgroundColor = Color(0xFF0A0A0A);
  static const Color _cardBackground = Color(0xFF191818);
  static const Color _primaryColor = Color(0xFFEA1E63);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9194A6);
  static const Color _textTertiary = Color(0xFF8E8E8E);
  static const Color _positiveColor = Colors.green;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: _buildContainerDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTitle(context),
          _buildValueInput(context),
          _buildLimitsSection(context),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: _cardBackground,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: _primaryColor,
          blurRadius: 10,
          spreadRadius: 0,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'Valor do PIX',
      style: TextStyle(
        color: Colors.white,
        fontSize: context.responsiveFont(20),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildValueInput(BuildContext context) {
    return TextField(
      controller: valueController,
      style: TextStyle(
        color: Colors.white,
        fontSize: context.responsiveFont(36), 
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
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
        CurrencyInputFormatter(),
      ],
    );
  }

  Widget _buildLimitsSection(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end, 
      children: [
        InfoRow(
          label: 'Limite atual',
          value: 'R\$ 750,00',
          labelColor: Colors.white70,
          valueColor: Colors.white,
          fontSize: context.responsiveFont(14),
        ),
        SizedBox(height: 6),
        InfoRow(
          label: 'Valor mínimo',
          value: 'R\$ 20,00',
          labelColor: Colors.white70,
          valueColor: Colors.white,
          fontSize: context.responsiveFont(14),
        ),
        SizedBox(height: 6),
        InfoRow(
          label: 'Limite diário por CPF/CNPJ',
          value: 'R\$ 5.000,00',
          labelColor: Colors.white70,
          valueColor: Colors.white,
          fontSize: context.responsiveFont(14),
        ),
      ],
    );
  }
}