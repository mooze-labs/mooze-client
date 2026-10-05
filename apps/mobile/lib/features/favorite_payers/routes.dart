import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/screens/favorite_payers_screen.dart';

final favoritePayersRoutes = [
  GoRoute(
    path: '/favorite-payers',
    builder: (context, state) => const FavoritePayersScreen(),
  ),
];
