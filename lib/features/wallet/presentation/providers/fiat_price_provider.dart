import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/features/wallet/di/providers/price_repository_provider.dart';

final fiatPriceProvider = FutureProvider<double>((ref) async {
  return 100000.00; // TODO: implement the real price
});
