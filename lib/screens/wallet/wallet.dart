import 'package:lwk/lwk.dart' as liquid;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/multichain/multichain_asset_provider.dart';
import 'package:mooze_mobile/screens/wallet/widgets/balance_display.dart';
import 'package:mooze_mobile/screens/wallet/widgets/wallet_buttons.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:mooze_mobile/widgets/mooze_drawer.dart';
import 'package:mooze_mobile/screens/wallet/widgets/coin_balance.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isBalanceVisible = true;
  int _selectedNavIndex = 2;

  @override
  void initState() {
    super.initState();
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  Future<List<liquid.Balance>> getLiquidAssetBalances(
    liquid.Wallet wallet,
  ) async {
    final balances = await wallet.balances();
    return balances;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Text(
        "Carteira",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: "roboto",
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: _toggleBalanceVisibility,
        ),
      ],
    );
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, "/send-funds");
        break;
      case 1:
        Navigator.pushNamed(context, "/receive-funds");
        break;
      case 2:
        break;
      case 3:
        Navigator.pushNamed(context, "/swap");
        break;
      case 4:
        Navigator.pushNamed(context, "/receive-pix-payment");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiChainAssetState = ref.watch(multiChainAssetsProvider.future);

    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: MoozeDrawer(),
      body: FutureBuilder<List<Asset>>(
        future: multiChainAssetState,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final assets = snapshot.data!;
          return Center(
            child: Column(
              children: [
                BalanceDisplay(isBalanceVisible: _isBalanceVisible),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    WalletButtonBox(
                      label: "Enviar",
                      icon: Icons.arrow_outward,
                      onTap: () => Navigator.pushNamed(context, "/send_funds"),
                    ),
                    WalletButtonBox(
                      label: "Receber",
                      icon: Icons.call_received,
                      onTap:
                          () => Navigator.pushNamed(context, "/receive_funds"),
                    ),
                    WalletButtonBox(
                      label: "Swap",
                      icon: Icons.swap_horiz,
                      onTap: () => Navigator.pushNamed(context, "/swap"),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  "Ativos",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 5),
                Expanded(
                  child: ListView.builder(
                    itemCount: assets.length,
                    itemBuilder:
                        (context, index) => CoinBalance(asset: assets[index]),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 40.0),
                  child: PrimaryButton(
                    text: "Receber por PIX",
                    onPressed:
                        () => Navigator.pushNamed(context, "/receive_pix"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
