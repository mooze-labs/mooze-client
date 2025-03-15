import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/providers/wallet/wallet_sync_provider.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';

class SplashScreen extends ConsumerStatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _preloadPriceData();

      final mnemonicHandler = MnemonicHandler();
      final mnemonic = await mnemonicHandler.retrieveWalletMnemonic(
        "mainWallet",
      );

      if (mnemonic != null) {
        await _initializeWallets(true, mnemonic);

        // Start periodic wallet sync
        ref.read(walletSyncServiceProvider.notifier).startPeriodicSync();

        Navigator.pushReplacementNamed(context, "/wallet");
      } else {
        Navigator.pushReplacementNamed(context, "/first_access");
      }
    } catch (e) {
      print("Error retrieving mnemonic: $e");
      // fallback to first_access screen
      Navigator.pushReplacementNamed(context, "/first_access");
    }
  }

  Future<void> _preloadPriceData() async {
    try {
      await ref.read(fiatPricesProvider.future);
    } catch (e) {
      print("Error preloading price data: $e");
    }
  }

  Future<void> _initializeWallets(bool isMainnet, String mnemonic) async {
    final liquidWalletNotifier = ref.read(
      liquidWalletNotifierProvider.notifier,
    );
    final bitcoinWalletNotifier = ref.read(
      bitcoinWalletNotifierProvider.notifier,
    );

    await Future.wait([
      liquidWalletNotifier.initializeWallet(isMainnet, mnemonic),
      bitcoinWalletNotifier.initializeWallet(isMainnet, mnemonic),
    ]);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/mooze-logo.png',
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
