import 'package:go_router/go_router.dart';

import 'presentation/screens/payment/screen.dart';
import 'presentation/screens/receive/screen.dart';

final pixRoutes = [
  GoRoute(
    path: "/pix/receive",
    builder: (context, state) => ReceivePixScreen(),
  ),
  GoRoute(
    path: "/pix/payment/:deposit_id",
    builder: (context, state) => PixPaymentScreen(),
  ),
];
