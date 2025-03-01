import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/bitcoin/wallet_provider.dart';
import 'package:mooze_mobile/providers/liquid/wallet_provider.dart';
import 'package:mooze_mobile/providers/mnemonic_provider.dart';

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
      final mnemonic = await ref.read(mnemonicNotifierProvider.future);
      if (mnemonic != null) {
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        Navigator.pushReplacementNamed(context, "/first_access");
      }
    } catch (e) {
      print("Error retrieving mnemonic: $e");
      // fallback to first_access screen
      Navigator.pushReplacementNamed(context, "/first_access");
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
