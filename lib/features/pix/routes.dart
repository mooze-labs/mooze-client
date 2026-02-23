import 'package:go_router/go_router.dart';

import 'presentation/screens/payment/screen.dart';
import 'presentation/screens/receive/presentation/screens/recive_pix_screen.dart';
import 'presentation/screens/human_verification/human_verification_intro_screen.dart';
import 'presentation/screens/human_verification/human_verification_payment_screen.dart';
import 'presentation/screens/human_verification/human_verification_code_screen.dart';
import 'presentation/screens/human_verification/human_verification_success_screen.dart';
import 'presentation/screens/pix_main_screen.dart';
import 'presentation/screens/pix_fees_screen.dart';
import 'presentation/screens/send/send_pix_input_screen.dart';
import 'presentation/screens/send/send_pix_confirm_screen.dart';
import 'presentation/screens/send/send_pix_processing_screen.dart';
import 'presentation/screens/send/send_pix_success_screen.dart';

final pixRoutes = [
  // GoRoute(path: "/pix", builder: (context, state) => PixMainScreen()),
  GoRoute(path: "/pix", builder: (context, state) => ReceivePixScreen()),

  GoRoute(path: "/pix/fees", builder: (context, state) => PixFeesScreen()),
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
  GoRoute(
    path: "/pix/send/input",
    builder: (context, state) => SendPixInputScreen(),
  ),
  GoRoute(
    path: "/pix/send/confirm",
    builder: (context, state) => SendPixConfirmScreen(),
  ),
  GoRoute(
    path: "/pix/send/processing/:withdraw_id",
    builder: (context, state) {
      final withdrawId = state.pathParameters["withdraw_id"] as String;
      return SendPixProcessingScreen(withdrawId: withdrawId);
    },
  ),
  GoRoute(
    path: "/pix/send/success/:withdraw_id",
    builder: (context, state) {
      final withdrawId = state.pathParameters["withdraw_id"] as String;
      return SendPixSuccessScreen(withdrawId: withdrawId);
    },
  ),
  GoRoute(
    path: "/human-verification",
    builder: (context, state) => HumanVerificationIntroScreen(),
  ),
  GoRoute(
    path: "/human-verification/payment",
    builder: (context, state) => HumanVerificationPaymentScreen(),
  ),
  GoRoute(
    path: "/human-verification/code",
    builder: (context, state) => HumanVerificationCodeScreen(),
  ),
  GoRoute(
    path: "/human-verification/success",
    builder: (context, state) => HumanVerificationSuccessScreen(),
  ),
];
