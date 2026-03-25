import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/human_verification/presentation/screens/human_verification_intro_screen.dart';
import 'package:mooze_mobile/features/pix/human_verification/presentation/screens/human_verification_payment_screen.dart';
import 'package:mooze_mobile/features/pix/human_verification/presentation/screens/human_verification_code_screen.dart';
import 'package:mooze_mobile/features/pix/human_verification/presentation/screens/human_verification_success_screen.dart';

final humanVerificationRoutes = [
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
