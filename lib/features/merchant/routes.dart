

import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_mode_screen.dart';

final merchantRoutes = [
  GoRoute(path: "/merchant", builder: (context, state) => MerchantModeScreen()),
];