import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/first_access/first_access.dart';
import 'package:mooze_mobile/screens/splash_screen/splash_screen.dart';
import 'package:mooze_mobile/themes/theme_base.dart' as mooze_theme;
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:mooze_mobile/screens/confirm-mnemonic.dart';
import 'package:mooze_mobile/screens/create-new-wallet.dart';
import 'package:mooze_mobile/screens/import_wallet/import_wallet.dart';
import 'package:mooze_mobile/screens/receive-funds.dart';
import 'package:mooze_mobile/screens/receive-pix-payment.dart';
import 'package:mooze_mobile/screens/send-funds.dart';
import 'package:mooze_mobile/screens/swap.dart';
import 'package:mooze_mobile/screens/wallet/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import 'package:lwk/lwk.dart';

void main() async {
  await LibLwk.init();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mooze',
      theme: mooze_theme.themeData,
      initialRoute: '/splash',
      routes: {
        // '/': (context) => StartScreen(),
        '/first_access': (context) => FirstAccessScreen(),
        '/splash': (context) => SplashScreen(),
        '/create-new-wallet': (context) => CreateNewWalletScreen(),
        '/confirm-mnemonic': (context) => ConfirmMnemonicScreen(),
        '/import-wallet': (context) => ImportWalletScreen(),
        '/wallet': (context) => WalletScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/receive-funds') {
          final wallet = settings.arguments as Wallet;
          return MaterialPageRoute(builder: (context) => ReceiveFundsScreen());
        }

        if (settings.name == '/receive-pix-payment') {
          final wallet = settings.arguments as Wallet;
          return MaterialPageRoute(
            builder: (context) => ReceivePixPaymentScreen(wallet: wallet),
          );
        }

        if (settings.name == '/send-funds') {
          final wallet = settings.arguments as Wallet;
          return MaterialPageRoute(builder: (context) => SendFundsScreen());
        }

        if (settings.name == '/swap') {
          final wallet = settings.arguments as Wallet;
          return MaterialPageRoute(
            builder: (context) => SwapScreen(wallet: wallet),
          );
        }
        return null;
      },
    );
  }
}

/*
class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF141818),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/mooze-logo.png', width: 200, height: 200),
            SizedBox(height: 50),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                children: [
                  HighlightedButton(
                    text: "Negociar agora",
                    onPressed: () {
                      Navigator.pushNamed(context, '/create-new-wallet');
                    },
                    icon: Icons.swap_horiz,
                  ),
                  SizedBox(height: 20),
                  CommonButton(
                    text: 'Acessar carteira',
                    onPressed: () {
                      Navigator.pushNamed(context, '/import-wallet');
                    },
                    icon: Icons.wallet_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
class StarryBackground extends StatelessWidget {
  final int starCount;
  final Color starColor;

  const StarryBackground({
    Key? key,
    this.starCount = 120,
    this.starColor = const Color(0xFFD973C1), // Pink color
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: CustomPaint(
        painter: _StarPainter(starCount: starCount, starColor: starColor),
        child: Container(),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final int starCount;
  final Color starColor;
  final Random _random = Random();

  _StarPainter({required this.starCount, required this.starColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = starColor.withOpacity(0.8);

    for (int i = 0; i < starCount; i++) {
      // Random position
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      // Random star radius, e.g. 0.5 to 2.0 px
      final radius = _random.nextDouble() * 1.5 + 0.5;

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}
