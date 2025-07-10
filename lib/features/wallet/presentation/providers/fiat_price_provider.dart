import 'package:flutter_riverpod/flutter_riverpod.dart';

final priceProvider = FutureProvider.autoDispose<double>((ref) async {
  return 106028.0;
});
