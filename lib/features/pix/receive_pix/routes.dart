import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/recive_pix_screen.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/payment/screen.dart';

final receivePixRoutes = [
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
