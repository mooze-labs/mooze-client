import 'package:go_router/go_router.dart';

import 'presentation/screens/home/home.dart';
import 'presentation/screens/send_funds/new_transaction_screen.dart';

final walletRoutes = [
  GoRoute(path: "/home", builder: (context, state) => HomeScreen()),
  GoRoute(path: "/wallet/send", builder: (context, state) => NewTransactionScreen()),
];