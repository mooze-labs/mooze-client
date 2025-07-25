// lib/pix/presentation/widgets/transaction_details_widget.dart
import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/extensions/responsive_extensions.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/info_row.dart';


class TransactionDetailsWidget extends StatelessWidget {
  const TransactionDetailsWidget({super.key});

  // Constants - Colors
  static const Color _cardBackground = Color(0xFF191818);
  static const Color _primaryColor = Color(0xFFEA1E63);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildContainerDecoration(),
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildHeader(),
            _buildAssetInfo(),
            _buildWalletAddress(),
            _buildDivider(),
            _buildFeesSection(context),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: _cardBackground,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Text(
        'Dados da transação',
        style: TextStyle(
          color: _primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAssetInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_buildAsset(), _buildAssetValue()],
      ),
    );
  }

  Widget _buildAsset() {
    return Row(
      children: [
        Image.asset('assets/images/logos/depix.png', width: 24, height: 24),
        SizedBox(width: 10),
        Text(
          'Depix',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetValue() {
    return Text(
      '=48.00',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildWalletAddress() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'lqlq qtu0 62sc ... xynf vd4r',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white24, thickness: 1);
  }

  Widget _buildFeesSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          InfoRow(
            label: 'Taxa Mooze',
            value: 'R\$ 1,00 (Taxa Fixa)',
            labelColor: Colors.white70,
            valueColor: Colors.white,
            fontSize: context.responsiveFont(14),
          ),
          SizedBox(height: 6),
          InfoRow(
            label: 'Taxa de parceiros',
            value: 'R\$ 1,00',
            labelColor: Colors.white70,
            valueColor: Colors.white,
            fontSize: context.responsiveFont(14),
          ),
          SizedBox(height: 6),
          InfoRow(
            label: 'Total de taxas',
            value: 'R\$ 2,00',
            labelColor: Colors.white70,
            valueColor: Colors.white,
            fontSize: context.responsiveFont(14),
          ),
        ],
      ),
    );
  }
}
