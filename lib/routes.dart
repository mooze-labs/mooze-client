import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/create_wallet/create_wallet.dart';
import 'package:mooze_mobile/screens/first_access/first_access.dart';
import 'package:mooze_mobile/screens/import_wallet/import_wallet.dart';
import 'package:mooze_mobile/screens/receive_funds/receive_funds.dart';
import 'package:mooze_mobile/screens/receive_pix/receive_pix.dart';
import 'package:mooze_mobile/screens/send_funds/send_funds.dart';
import 'package:mooze_mobile/screens/settings/settings.dart';
import 'package:mooze_mobile/screens/settings/terms_and_conditions.dart';
import 'package:mooze_mobile/screens/splash_screen/splash_screen.dart';
import 'package:mooze_mobile/screens/store_mode/store_home.dart';
import 'package:mooze_mobile/screens/swap/input_peg.dart';
import 'package:mooze_mobile/screens/swap/swap.dart';
import 'package:mooze_mobile/screens/transaction_history/transaction_history.dart';
import 'package:mooze_mobile/screens/wallet/wallet.dart';

final Map<String, WidgetBuilder> appRoutes = {
  //"/": (context) => HomeScreen(),
  "/splash": (context) => SplashScreen(),
  "/first_access": (context) => FirstAccessScreen(),
  "/create_wallet": (context) => CreateWalletScreen(),
  "/import_wallet": (context) => ImportWalletScreen(),
  "/wallet": (context) => WalletScreen(),
  "/send_funds": (context) => SendFundsScreen(),
  "/receive_pix": (context) => ReceivePixScreen(),
  "/receive_funds": (context) => ReceiveFundsScreen(),
  "/swap": (context) => SideswapScreen(),
  "/transaction_history": (context) => TransactionHistoryScreen(),
  "/store_mode": (context) => StoreHomeScreen(),
  "/settings": (context) => SettingsScreen(),
  "/terms-and-conditions": (context) => TermsAndConditionsScreen(),
  "/input_peg": (context) => InputPegScreen(),
};
