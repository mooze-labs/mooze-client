import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/providers/wallet/wallet_sync_provider.dart';
import 'package:mooze_mobile/repositories/wallet/bitcoin.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/services/mooze/registration.dart';
import 'package:mooze_mobile/services/mooze/user.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';
import 'package:mooze_mobile/utils/store_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

String BACKEND_URL = String.fromEnvironment(
  "BACKEND_URL",
  defaultValue: "10.0.2.2:8080",
);

class SplashScreen extends ConsumerStatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _authService = AuthenticationService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> redirectToWallet(BuildContext context) async {
    final isStoreMode = await StoreModeHandler().isStoreMode();
    if (!context.mounted) return;

    if (isStoreMode) {
      Navigator.pushReplacementNamed(context, "/store_mode");
    } else {
      Navigator.pushReplacementNamed(context, "/wallet");
    }
  }

  Future<void> _initializeApp() async {
    try {
      await _preloadPriceData();

      final noScreenshot = NoScreenshot.instance;
      await noScreenshot.screenshotOn();

      final mnemonicHandler = MnemonicHandler();
      final mnemonic = await mnemonicHandler.retrieveWalletMnemonic(
        "mainWallet",
      );

      final isPinSetup = await _authService.isPinSetup();
      if (!isPinSetup && mounted) {
        Navigator.pushReplacementNamed(context, "/first_access");
      }

      debugPrint("Mnemonic: $mnemonic");

      if (mnemonic != null) {
        await _initializeWallets(true, mnemonic);
        ref.read(walletSyncServiceProvider.notifier).syncNow();

        // Start periodic wallet sync
        ref.read(walletSyncServiceProvider.notifier).startPeriodicSync();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => VerifyPinScreen(
                    onPinConfirmed: () async => await redirectToWallet(context),
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/first_access");
        }
      }
    } catch (e) {
      print("Error retrieving mnemonic: $e");
      // fallback to first_access screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/first_access");
      }
    }
  }

  Future<bool> _checkServerHealth() async {
    try {
      final response = await http
          .get(
            (kDebugMode)
                ? Uri.parse('http://$BACKEND_URL/health')
                : Uri.parse('https://$BACKEND_URL/health'),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              if (kDebugMode) {
                print("Server health check timed out after 5 seconds");
              }
              throw TimeoutException('Server health check timed out');
            },
          );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print("Server health check failed: $e");
      }
      return false;
    }
  }

  Future<void> _preloadUserData(String descriptor) async {
    try {
      final isServerHealthy = await _checkServerHealth();
      if (!isServerHealthy) {
        if (kDebugMode) {
          print("Server is not healthy, skipping user data preload");
        }
        return;
      }

      final userService = UserService(backendUrl: BACKEND_URL);
      final user = await userService.getUserDetails();

      if (kDebugMode) {
        print("User: $user");
      }
    } catch (e) {
      print("Error preloading user data: $e");
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

    final repository =
        ref.read(bitcoinWalletRepositoryProvider) as BitcoinWalletRepository;
    final descriptor = repository.publicDescriptor;
    if (descriptor != null) {
      await _preloadUserData(descriptor);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Image.asset(
              'assets/images/mooze-logo.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
