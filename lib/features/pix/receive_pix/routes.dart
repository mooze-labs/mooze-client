import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/receive_pix_screen.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/pix_confirmation_screen.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/payment/pix_payment_screen.dart';

final receivePixRoutes = [
  GoRoute(
    path: "/pix/receive",
    builder: (context, state) => ReceivePixScreen(),
  ),
  GoRoute(
    path: "/pix/confirm",
    builder: (context, state) => const PixConfirmationScreen(),
  ),
  GoRoute(
    path: "/pix/payment/:transaction_id",
    pageBuilder: (context, state) {
      return NoTransitionPage(child: PixPaymentScreen());
    },
  ),
];
