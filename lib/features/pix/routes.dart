import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/receive_pix/routes.dart';
import 'package:mooze_mobile/features/pix/send_pix/routes.dart';
import 'package:mooze_mobile/features/pix/human_verification/routes.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/screens/pix_main_screen.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/screens/pix_fees_screen.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/recive_pix_screen.dart';

final pixRoutes = [
  // GoRoute(path: "/pix", builder: (context, state) => PixMainScreen()),
  GoRoute(path: "/pix", builder: (context, state) => ReceivePixScreen()),

  GoRoute(path: "/pix/fees", builder: (context, state) => PixFeesScreen()),

  ...receivePixRoutes,
  ...sendPixRoutes,
  ...humanVerificationRoutes,
];
