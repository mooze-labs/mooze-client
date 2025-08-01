import 'package:go_router/go_router.dart';

import 'presentation/screens/home/home.dart';

final walletRoutes = [
  GoRoute(path: "/wallet", builder: (context, state) => HomeScreen())
];