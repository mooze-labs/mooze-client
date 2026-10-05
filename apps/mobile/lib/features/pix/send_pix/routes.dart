import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/send_pix/presentation/screens/send_pix_input_screen.dart';
import 'package:mooze_mobile/features/pix/send_pix/presentation/screens/send_pix_confirm_screen.dart';
import 'package:mooze_mobile/features/pix/send_pix/presentation/screens/send_pix_processing_screen.dart';
import 'package:mooze_mobile/features/pix/send_pix/presentation/screens/send_pix_success_screen.dart';

final sendPixRoutes = [
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
];
