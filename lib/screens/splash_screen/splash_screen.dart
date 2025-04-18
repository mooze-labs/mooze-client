import 'dart:convert';

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
import 'package:no_screenshot/no_screenshot.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

String BACKEND_URL = String.fromEnvironment(
  "BACKEND_URL",
  defaultValue: "api.mooze.app",
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
      if (kDebugMode) {
        print("Error retrieving mnemonic: $e");
      }
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
    if (kDebugMode) {
      print("=== PRELOAD USER DATA STARTED ===");
      print("Descriptor: $descriptor");
    }

    try {
      // Generate hash of descriptor
      final hashedDescriptor =
          sha256.convert(utf8.encode(descriptor)).toString();
      if (kDebugMode) {
        print("Hashed descriptor: $hashedDescriptor");
      }

      // Store hashed descriptor
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setString('hashed_descriptor', hashedDescriptor);

      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        print("FCM token: $fcmToken");
      }

      // Check if user exists
      final checkUserUrl = Uri.https(BACKEND_URL, "/users/$hashedDescriptor");
      if (kDebugMode) {
        print("Checking user existence at: $checkUserUrl");
      }

      final checkResponse = await http.get(checkUserUrl);
      if (kDebugMode) {
        print("User check response:");
        print("Status code: ${checkResponse.statusCode}");
        print("Response body: ${checkResponse.body}");
      }

      if (checkResponse.statusCode == 404 || checkResponse.statusCode == 500) {
        // User doesn't exist or server error, try to register them
        if (kDebugMode) {
          print(
            "=== USER NOT FOUND OR SERVER ERROR, ATTEMPTING REGISTRATION ===",
          );
        }

        final registerUrl = Uri.https(BACKEND_URL, "/users");
        final registerResponse = await http.post(
          registerUrl,
          headers: <String, String>{"Content-Type": "application/json"},
          body: jsonEncode({
            "descriptor_hash": hashedDescriptor,
            "fcm_token": fcmToken,
            "referral_code": null,
          }),
        );

        if (kDebugMode) {
          print("Registration response:");
          print("Status code: ${registerResponse.statusCode}");
          print("Response body: ${registerResponse.body}");
        }

        if (registerResponse.statusCode != 201 &&
            registerResponse.statusCode != 200) {
          if (kDebugMode) {
            print("=== REGISTRATION FAILED, BUT PROCEEDING ANYWAY ===");
            print("Error: ${registerResponse.body}");
          }
        } else {
          if (kDebugMode) {
            print("=== USER REGISTERED SUCCESSFULLY ===");
          }
        }
      } else if (checkResponse.statusCode == 200) {
        if (kDebugMode) {
          print("=== USER ALREADY EXISTS ===");
        }
      } else {
        if (kDebugMode) {
          print("=== UNEXPECTED RESPONSE, BUT PROCEEDING ANYWAY ===");
          print("Status code: ${checkResponse.statusCode}");
          print("Response body: ${checkResponse.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("=== ERROR IN PRELOAD USER DATA, BUT PROCEEDING ANYWAY ===");
        print("Error: $e");
      }
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
    if (kDebugMode) {
      print("=== INITIALIZE WALLETS STARTED ===");
      print("isMainnet: $isMainnet");
    }

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
      if (kDebugMode) {
        print("Descriptor obtained: $descriptor");
        print("Calling preloadUserData...");
      }
      await _preloadUserData(descriptor);
    } else {
      if (kDebugMode) {
        print("No descriptor available, skipping preloadUserData");
      }
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
