import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/receive_pix_screen.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/pix_confirmation_screen.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/payment/pix_payment_screen.dart';

/// Routes of the deposit flow: the user adds money to their own Mooze wallet
/// with a real Pix charge created by the Mooze API.
///
/// The hub reaches this flow through `/pix/deposit`.
final receivePixRoutes = [
  GoRoute(
    path: "/pix/deposit",
    builder: (context, state) => ReceivePixScreen(),
  ),
  GoRoute(
    path: "/pix/confirm",
    builder: (context, state) => const PixConfirmationScreen(),
  ),
  GoRoute(
    path: "/pix/payment/:transaction_id",
    builder: (context, state) => const PixPaymentScreen(),
  ),
];
