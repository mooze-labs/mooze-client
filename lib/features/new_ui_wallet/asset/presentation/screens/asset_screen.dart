import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/new_ui_wallet/asset/data/asset_page_data.dart';
import 'package:mooze_mobile/features/new_ui_wallet/asset/presentation/widgets/action_button.dart';
import 'package:mooze_mobile/features/new_ui_wallet/asset/presentation/widgets/asset_transaction_item.dart';

// Tela principal de Ativos
class AssetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildActionButtons(),
          _buildAssetsLabel(),
          Expanded(child: _buildAssetsList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF0A0A0A),
      elevation: 0,
      title: Text(
        'Ativos',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minha Carteira',
                style: TextStyle(color: Color(0xFF9194A6), fontSize: 16),
              ),
              IconButton(
                icon: Icon(Icons.visibility_off, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'R\$ 54,292.79',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+7.86%',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ActionButton(
              icon: Icons.send,
              label: 'Enviar',
              onPressed: () {},
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ActionButton(
              icon: Icons.qr_code_scanner,
              label: 'Receber',
              onPressed: () {},
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ActionButton(
              icon: Icons.swap_horiz,
              label: 'Swap',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsLabel() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            'Ativos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsList() {
    final assets = _getAssetsMockData();

    return ListView.builder(
      itemCount: assets.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: AssetTransactionItem(
            icon: assets[index].iconText,
            title: assets[index].name,
            subtitle: assets[index].amount,
            value: assets[index].value,
            time: assets[index].percentage,
          ),
        );
      },
    );
  }

  List<AssetPageData> _getAssetsMockData() {
    return [
      AssetPageData(
        id: '1',
        name: 'Bitcoin',
        symbol: 'BTC',
        amount: '0.18 BTC',
        value: 'R\$ 40.012,21',
        percentage: '+7%',
        isPositive: true,
        iconColor: Color(0xFFF7931A),
        iconText: 'assets/images/logos/btc.png',
      ),
      AssetPageData(
        id: '2',
        name: 'Tether USDT',
        symbol: 'USDT',
        amount: '2420.43 USDT',
        value: 'R\$ 14.280,58',
        percentage: '-3%',
        isPositive: true,
        iconColor: Color(0xFF26A69A),
        iconText: 'assets/images/logos/usdt.png',
      ),
    ];
  }

  void _onAssetTapped(AssetPageData asset) {
    print('Ativo selecionado: ${asset.name}');
  }
}