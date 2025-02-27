import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lwk/lwk.dart' as liquid;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/liquid/asset_provider.dart';
import 'package:mooze_mobile/providers/liquid/wallet_provider.dart';
import 'package:mooze_mobile/providers/bitcoin/wallet_provider.dart';
import 'package:mooze_mobile/providers/external/price_provider.dart';
import 'package:mooze_mobile/screens/wallet/widgets/balance_display.dart';
import 'package:mooze_mobile/widgets/mooze_drawer.dart';
import 'package:mooze_mobile/widgets/mooze_bottom_nav.dart';
import 'package:mooze_mobile/screens/wallet/widgets/coin_balance.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isBalanceVisible = true;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWallet(true);
    });
  }

  Future<void> _initializeWallet(bool mainnet) async {
    final btcNetwork =
        (mainnet == true) ? bitcoin.Network.bitcoin : bitcoin.Network.testnet;
    final liquidNetwork =
        (mainnet == true) ? liquid.Network.mainnet : liquid.Network.testnet;

    final liquidWalletNotifier = ref.read(
      liquidWalletNotifierProvider.notifier,
    );
    final bitcoinWalletNotifier = ref.read(
      bitcoinWalletNotifierProvider.notifier,
    );
    await Future.wait([
      liquidWalletNotifier.initializeWallet(liquidNetwork),
      bitcoinWalletNotifier.initializeWallet(btcNetwork),
    ]);
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
      backgroundColor: Colors.black,
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Image.asset(
        'assets/mooze-logo.png',
        width: 120,
        fit: BoxFit.contain,
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

  /*
  Widget _buildMultichainBalanceDisplay(
    AsyncValue<double> btcPriceStream,
    AsyncValue<bitcoin.Wallet> bitcoinWalletState,
    AsyncValue<liquid.Wallet> liquidWalletState,
    bool onlyOnChain,
    bool isBalanceVisible,
  ) {
    final amount =
        (onlyOnChain == true) ? onChainAmount : onChainAmount + sideChainAmount;

    return _buildBalanceDisplay(btcPriceStream, amount, isBalanceVisible);
  }
  */

  Widget _buildMultiChainBalanceDisplay(
    AsyncValue<double> btcPriceStream,
    AsyncValue<bitcoin.Wallet> bitcoinWalletState,
    bool isBalanceVisible,
  ) {
    return bitcoinWalletState.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => ErrorBalanceDisplay(error: err.toString()),
      data: (wallet) {
        final amount = wallet.getBalance().total.toInt();
        return _buildBalanceDisplay(btcPriceStream, amount, isBalanceVisible);
      },
    );
  }

  Widget _buildBalanceDisplay(
    AsyncValue<double> btcPriceStream,
    int amount,
    bool isBalanceVisible,
  ) {
    return btcPriceStream.when(
      loading: () => const CircularProgressIndicator(),
      error:
          (err, stack) => BalanceDisplay(
            totalSats: amount,
            isBalanceVisible: isBalanceVisible,
          ),
      data:
          (btcPriceBrl) => BalanceDisplay(
            totalSats: amount,
            btcPriceBrl: btcPriceBrl,
            isBalanceVisible: isBalanceVisible,
          ),
    );
  }

  Widget _fetchBitcoinWalletDisplay(
    AsyncValue<bitcoin.Wallet> bitcoinWalletState,
  ) {
    return bitcoinWalletState.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text("Error: $err"),
      data: (wallet) {
        final coinBalance = CoinBalance(
          name: "Bitcoin",
          amount: wallet.getBalance().total.toInt(),
          unitName: "BTC",
          precision: 8,
          logo: Image.asset("assets/bitcoin-logo.png", width: 40, height: 40),
        );

        return CoinBalanceList(coinBalances: [coinBalance]);
      },
    );
  }

  Widget _fetchLiquidWalletDisplay(
    AsyncValue<liquid.Wallet> liquidWalletState,
    liquid.Network network,
  ) {
    return liquidWalletState.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text("Error: $err"),
      data: (wallet) {
        return _buildLiquidWalletDisplay(wallet, network);
      },
    );
  }

  Widget _buildLiquidWalletDisplay(
    liquid.Wallet wallet,
    liquid.Network network,
  ) {
    return FutureBuilder<List<liquid.Balance>>(
      future: wallet.balances(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text("Error fetching Liquid assets: ${snapshot.error}");
        }

        final lBtcId =
            (network == liquid.Network.mainnet)
                ? liquid.lBtcAssetId
                : liquid.lTestAssetId;

        final balances = snapshot.data ?? [];
        final assetDisplays =
            balances
                .map(
                  (balance) => _buildLiquidAssetDisplay(
                    balance.assetId,
                    balance.value,
                    network,
                  ),
                )
                .toList();

        return CoinBalanceList(coinBalances: assetDisplays);
      },
    );
  }

  Widget _buildLiquidAssetDisplay(
    String assetId,
    int amount,
    liquid.Network network,
  ) {
    if (assetId == liquid.lBtcAssetId) {
      return CoinBalance(
        name: "Liquid Bitcoin",
        amount: amount,
        unitName: "L-BTC",
        precision: 8,
        logo: Image.asset("assets/lbtc-logo.png", height: 40, width: 40),
      );
    }
    final assetState = ref.watch(liquidAssetProvider((assetId, network)));
    final image = CachedNetworkImage(
      imageUrl: "https://liquid.network/api/v1/asset/$assetId/icon",
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      width: 40,
      height: 40,
    );

    return assetState.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text("Error: $err"),
      data: (assetData) {
        return CoinBalance(
          name: assetData.name,
          amount: amount,
          unitName: assetData.ticker,
          precision: assetData.precision,
          logo: image,
        );
      },
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
        Navigator.pushNamed(context, "/swap");
        break;
      case 3:
        Navigator.pushNamed(context, "/receive-pix-payment");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bitcoinWalletState = ref.watch(bitcoinWalletNotifierProvider);
    final liquidWalletState = ref.watch(liquidWalletNotifierProvider);
    final btcPriceStream = ref.watch(bitcoinPriceProvider);

    if (bitcoinWalletState.isLoading || liquidWalletState.isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        drawer: MoozeDrawer(),
        appBar: _buildAppBar(context),
        body: Stack(
          children: [const Center(child: CircularProgressIndicator())],
        ),
        bottomNavigationBar: MoozeBottomNav(
          currentIndex: _selectedNavIndex,
          onItemTapped: _onNavItemTapped,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      drawer: const MoozeDrawer(),
      appBar: _buildAppBar(context),
      body: Center(
        child: Column(
          children: [
            _buildMultiChainBalanceDisplay(
              btcPriceStream,
              bitcoinWalletState,
              _isBalanceVisible,
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 8.0,
                bottom: 8.0,
              ),
              child: _fetchBitcoinWalletDisplay(bitcoinWalletState),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 8.0,
                bottom: 8.0,
              ),
              child: _fetchLiquidWalletDisplay(
                liquidWalletState,
                liquid.Network.mainnet,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MoozeBottomNav(
        currentIndex: _selectedNavIndex,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }
}
