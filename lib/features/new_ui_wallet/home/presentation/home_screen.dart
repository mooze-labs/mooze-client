import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/new_ui_wallet/home/widgets/asset_card.dart';
import 'package:mooze_mobile/features/new_ui_wallet/home/widgets/home_transaction_item.dart';

class MoozeHomepage extends StatelessWidget {
  const MoozeHomepage({super.key});

  // Constants - Colors
  static const Color _backgroundColor = Color(0xFF0A0A0A);
  static const Color _primaryColor = Color(0xFFEA1E63);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9194A6);
  static const Color _textTertiary = Color(0xFF8E8E8E);
  static const Color _positiveColor = Colors.green;

  // Constants - Dimensions
  static const double _horizontalPadding = 16.0;
  static const double _logoWidth = 117.0;
  static const double _logoHeight = 24.0;
  static const double _logoOpacity = 0.2;
  static const double _balanceFontSize = 32.0;
  static const double _sectionTitleFontSize = 16.0;
  static const double _buttonVerticalPadding = 16.0;
  static const double _borderRadius = 8.0;
  static const double _cardSpacing = 12.0;
  static const double _itemSpacing = 12.0;

  // Constants - Mock Data
  static const String _mockBalance = 'R\$ 54,292.79';
  static const String _mockPercentage = '+7.86%';

  @override
  Widget build(BuildContext context) {
    _configureSystemUI();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildWalletSection(),
                _buildActionButtons(),
                _buildAssetsSection(),
                _buildTransactionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Opacity(
            opacity: _logoOpacity,
            child: Image.asset(
              'assets/logos/5.png',
              width: _logoWidth,
              height: _logoHeight,
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildWalletSection() {
    return Column(
      children: [
        _buildWalletHeader(),
        _buildBalanceRow(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWalletHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Minha Carteira',
          style: TextStyle(
            color: _textSecondary,
            fontSize: _sectionTitleFontSize,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.visibility_off, color: _textPrimary),
          onPressed: _toggleBalanceVisibility,
        ),
      ],
    );
  }

  Widget _buildBalanceRow() {
    return Row(
      children: [
        const Text(
          _mockBalance,
          style: TextStyle(
            color: _textPrimary,
            fontSize: _balanceFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        _buildPercentageTag(),
      ],
    );
  }

  Widget _buildPercentageTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _positiveColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        _mockPercentage,
        style: TextStyle(
          color: _positiveColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildReceiveButton()),
            const SizedBox(width: _cardSpacing),
            Expanded(child: _buildSendButton()),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildReceiveButton() {
    return ElevatedButton(
      onPressed: _handleReceiveAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(vertical: _buttonVerticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
      child: const Text(
        'RECEBER',
        style: TextStyle(
          fontSize: _sectionTitleFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return ElevatedButton(
      onPressed: _handleSendAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: _textPrimary,
        padding: const EdgeInsets.symmetric(vertical: _buttonVerticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
      child: const Text(
        'ENVIAR',
        style: TextStyle(
          fontSize: _sectionTitleFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAssetsSection() {
    return Column(
      children: [
        _buildSectionHeader('Ativos', 'Ver mais', _handleViewMoreAssets),
        const SizedBox(height: 16),
        _buildAssetsCards(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAssetsCards() {
    return Row(
      children: [
        Expanded(
          child: AssetCard(
            icon: 'assets/images/logos/btc.png',
            title: 'Bitcoin',
            value: 'R\$ 660.000,00',
            percentage: '7% increase',
            isPositive: true,
          ),
        ),
        const SizedBox(width: _cardSpacing),
        Expanded(
          child: AssetCard(
            icon: 'assets/images/logos/usdt.png',
            title: 'USDT',
            value: 'R\$ 5,90',
            percentage: '3% increase',
            isPositive: false,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      children: [
        _buildSectionHeader(
          'Transações',
          'Ver mais',
          _handleViewMoreTransactions,
        ),
        const SizedBox(height: 16),
        _buildTransactionsList(),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText,
    VoidCallback onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: _sectionTitleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionText,
            style: const TextStyle(color: _textTertiary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    final transactions = _getMockTransactions();

    return Column(
      children: transactions.map((transaction) {
        return Padding(
          padding: const EdgeInsets.only(bottom: _itemSpacing),
          child: HomeTransactionItem(
            icon: transaction['icon']!,
            title: transaction['title']!,
            subtitle: transaction['subtitle']!,
            value: transaction['value']!,
            time: transaction['time']!,
          ),
        );
      }).toList(),
    );
  }
  
  /// Mock
  List<Map<String, String>> _getMockTransactions() {
    return [
      {
        'icon': 'assets/images/logos/btc.png',
        'title': 'Bitcoin',
        'subtitle': '0.04 BTC',
        'value': 'R\$40.012,21',
        'time': 'Há 2 horas',
      },
      {
        'icon': 'assets/images/logos/usdt.png',
        'title': 'Tether USDT',
        'subtitle': '2420.43 USDT',
        'value': 'R\$-14.280,58',
        'time': 'Há 1 semana',
      },
      {
        'icon': 'assets/images/logos/btc.png',
        'title': 'Bitcoin',
        'subtitle': '0.04 BTC',
        'value': 'R\$40.012,21',
        'time': 'Há 1 mês',
      },
      {
        'icon': 'assets/images/logos/btc.png',
        'title': 'Bitcoin',
        'subtitle': '0.04 BTC',
        'value': 'R\$40.012,21',
        'time': 'Há 2 meses',
      },
    ];
  }

  // Action Handlers
  void _toggleBalanceVisibility() {
    // TODO: Implement balance visibility toggle
  }

  void _handleReceiveAction() {
    // TODO: Implement receive action
  }

  void _handleSendAction() {
    // TODO: Implement send action
  }

  void _handleViewMoreAssets() {
    // TODO: Implement navigation to view more assets
  }

  void _handleViewMoreTransactions() {
    // TODO: Implement navigation to view more transactions
  }
}