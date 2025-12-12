import 'package:go_router/go_router.dart';

import 'presentation/screens/payment/screen.dart';
import 'presentation/screens/receive/presentation/screens/recive_pix_screen.dart';

final pixRoutes = [
  GoRoute(
    path: "/pix/receive",
    builder: (context, state) => ReceivePixScreen(),
  ),
  GoRoute(
    path: "/pix/payment/:transaction_id",
    pageBuilder: (context, state) {
      return NoTransitionPage(child: PixPaymentScreen());
    },
  ),
];
