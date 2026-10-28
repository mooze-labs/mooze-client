import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/routes.dart';
import 'package:mooze_mobile/features/pix/receive_pix/routes.dart';
import 'package:mooze_mobile/features/pix/human_verification/routes.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/screens/pix_fees_screen.dart';

final pixRoutes = [
  GoRoute(path: "/pix/fees", builder: (context, state) => PixFeesScreen()),

  ...pixHubRoutes,
  ...receivePixRoutes,
  ...humanVerificationRoutes,
];
