import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/screens/address_explorer_screen.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/screens/address_ownership_screen.dart';

final addressExplorerRoutes = [
  GoRoute(
    path: '/settings/address-explorer',
    builder: (context, state) => const AddressExplorerScreen(),
  ),
  GoRoute(
    path: '/settings/address-ownership',
    builder: (context, state) => const AddressOwnershipScreen(),
  ),
];
