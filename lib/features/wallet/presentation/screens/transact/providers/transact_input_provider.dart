import 'package:flutter_riverpod/flutter_riverpod.dart';

final StateProvider<int> satoshiInputProvider = StateProvider<int>((ref) {
  return 0;
});

final StateProvider<double> fiatInputProvider = StateProvider<double>((ref) {
  return 0.0;
});

final StateProvider<String> fiatInputStringProvider = StateProvider<String>((
  ref,
) {
  return '';
});
