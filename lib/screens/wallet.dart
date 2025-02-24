import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;
import 'package:lwk/lwk.dart' as liquid;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/liquid/wallet_provider.dart';
import 'package:mooze_mobile/providers/bitcoin/wallet_provider.dart';
import 'package:mooze_mobile/providers/price_provider.dart';
import 'package:mooze_mobile/widgets/mooze_drawer.dart';
import 'package:mooze_mobile/widgets/mooze_bottom_nav.dart';
import 'package:mooze_mobile/widgets/asset_item.dart';
import 'package:mooze_mobile/widgets/wallet_balance_display.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final Map<String, Map<String, String>> assetInfo = {
    // Liquid Bitcoin
    '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d': {
      'name': 'Liquid Bitcoin',
      'logo': 'assets/lbtc-logo.png',
    },
    // Depix
    '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189': {
      'name': 'Depix',
      'logo': 'assets/depix-logo.png',
    },
    // USDt
    'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2': {
      'name': 'USDt',
      'logo': 'assets/usdt-logo.png',
    },
  };

  bool _isBalanceVisible = true;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWallet();
    });
  }

  Future<void> _initializeWallet(bool mainnet) async {
    final btcNetwork = (mainnet == true) ? bitcoin.Network.bitcoin : bitcoin.Network.testnet;
    final liquidNetwork = (mainnet == true) ? liquid.Network.mainnet : liquid.Network.testnet;

    final liquidWalletNotifier = ref.read(liquidWalletNotifierProvider.notifier);
    final bitcoinWalletNotifier = red.read(bitcoinWalletNotifierProvider.notifier);
    await Future.wait([
    	liquidWalletNotifier.initializeWallet(liquid.Network.mainnet),
    	bitcoinWalletNotifier.initializeWallet(bitcoin.Network.bitcoin),
    ]);
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  int getOnchainBalance() {
  	final wallet = ref.read(bitcoinWalletNotifierProvider);
  	final balance = wallet.getBalance().total;

	return balance.toInt();
  }

  /// Sums LBTC from lwk
  double _sumLiquidBitcoin(List<Balance> allBalances, bool mainnet) {
    final lbtcId = (mainnet == true) ? liquid.lBtcAssetId : liquid.lTestAssetId;
    final lbtcBalance = allBalances.firstWhere(
      (b) => b.assetId == lbtcId,
      orElse: () => Balance(assetId: lbtcId, value: 0),
    );
    return lbtcBalance.value / 100000000.0;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
  	return AppBar(
		backgroundColor: Colors.black,
		elevation: 0,
		leading: Builder(
			builder: (context) {
				return IconButton(
					icon: const Icon(Icons.meny, color: Colors.white),
					onPressed: () => Scaffold.of(context).openDrawer(),
				);
			},
		),
		title: Image.asset('assets/mooze-logo.png', width: 120, fit: BoxFit.contain),
		centerTitle: true,
		actions: [
			IconButton(
				icon: Icon(_isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white),
				onPressed: _toggleBalanceVisibility
			),
		],
	);
  }

  @override
  Widget build(BuildContext context) {
    final liquidWalletState = ref.watch(liquidWalletNotifierProvider);
    final bitcoinWalletState = ref.watch(bitcoinWalletNotifierProvider);
    final btcPriceStream = ref.watch(bitcoinPriceProvider);

    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      drawer: const MoozeDrawer(),
      appBar: _buildAppBar(context), 
      body: Stack(
        children: [
          _StarryBackground(),
          // Main content
          Center(
            child: liquidWalletState.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, st) => Text(
                "Erro: $err",
                style: const TextStyle(color: Colors.red),
              ),
              data: (wallet) {
                if (wallet == null) {
                  return const Text(
                    "Carteira não carregada",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  );
                }

                // We have a wallet, so fetch balances
                return FutureBuilder<List<Balance>>(
                  future: wallet.balances(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text(
                        "Erro ao buscar saldo: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      );
                    }

                    final balances = snapshot.data ?? [];
                    // Watch the BTC price
                    return btcPriceStream.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (err, st) => Text(
                        "Erro ao buscar preço BTC: $err",
                        style: const TextStyle(color: Colors.red),
                      ),
                      data: (btcPriceBrl) {
                        final totalBtc = _sumLiquidBitcoin(balances);

                        return Column(
                          children: [
                            ModernBalanceDisplay(
                              totalBtc: totalBtc,
                              btcPriceBrl: btcPriceBrl,
                              isBalanceVisible: _isBalanceVisible,
                            ),

                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                itemCount: balances.length,
                                itemBuilder: (context, index) {
                                  final balance = balances[index];
                                  final asset = assetInfo[balance.assetId] ??
                                      {
                                        'name': 'Unknown',
                                        'logo': 'assets/default.png'
                                      };

                                  return AssetItem(
                                    assetName: asset['name']!,
                                    assetIconPath: asset['logo']!,
                                    balance: balance.value.toString(),
                                    isBalanceVisible: _isBalanceVisible,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: MoozeBottomNav(
        currentIndex: _selectedNavIndex,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, "/send-funds", arguments: wallet);
        break;
      case 1:
        Navigator.pushNamed(context, "/receive-funds", arguments: wallet);
        break;
      case 2:
        Navigator.pushNamed(context, "/swap", arguments: wallet);
        break;
      case 3:
        Navigator.pushNamed(context, "/receive-pix-payment", arguments: wallet);
        break;
    }
  }
}

class Balance {
	final String asset;
	final String network;
	final int amount;

	Balance({
		required this.asset,
		required this.network,
		required this.amount
	)};
}
