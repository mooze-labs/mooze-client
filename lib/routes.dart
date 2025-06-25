import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => SplashScreen()),
    GoRoute(
      path: '/first_access',
      builder: (context, state) => FirstAccessScreen(),
    ),
    GoRoute(
      path: '/create_wallet',
      builder: (context, state) => CreateWalletScreen(),
    ),
    GoRoute(
      path: '/import_wallet',
      builder: (context, state) => ImportWalletScreen(),
    ),
    GoRoute(path: '/wallet', builder: (context, state) => WalletScreen()),
    GoRoute(
      path: '/send_funds',
      builder: (context, state) => SendFundsScreen(),
    ),
    GoRoute(
      path: '/receive_pix',
      builder: (context, state) => ReceivePixScreen(),
    ),
    GoRoute(
      path: '/receive_funds',
      builder: (context, state) => ReceiveFundsScreen(),
    ),
    GoRoute(path: '/swap', builder: (context, state) => SideswapScreen()),
    GoRoute(
      path: '/transaction_history',
      builder: (context, state) => TransactionHistoryScreen(),
    ),
    GoRoute(
      path: '/store_mode',
      builder: (context, state) => StoreHomeScreen(),
    ),
    GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),
    GoRoute(
      path: '/terms-and-conditions',
      builder: (context, state) => TermsAndConditionsScreen(),
    ),
    GoRoute(path: '/input_peg', builder: (context, state) => InputPegScreen()),
  ],
);
