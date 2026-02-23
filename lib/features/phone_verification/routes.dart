import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/phone_verification/presentation/screeens/phone_verification_code_screen.dart';
import 'package:mooze_mobile/features/phone_verification/presentation/screeens/phone_verification_intro_screen.dart';
import 'package:mooze_mobile/features/phone_verification/presentation/screeens/phone_verification_method_screen.dart';

final phoneVerificationRoutes = [
  GoRoute(
    path: "/phone-verification/intro",
    builder: (context, state) => PhoneVerificationIntroScreen(),
  ),
  GoRoute(
    path: "/phone-verification/method",
    builder: (context, state) => PhoneVerificationMethodScreen(),
  ),
  GoRoute(
    path: "/phone-verification/code",
    builder:
        (context, state) => PhoneVerificationCodeScreen(onPinConfirmed: () {}),
  ),
];
