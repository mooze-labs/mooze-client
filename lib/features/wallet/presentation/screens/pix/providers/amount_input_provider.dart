import 'package:flutter_riverpod/flutter_riverpod.dart';

final StateProvider<double> amountInputProvider = StateProvider<double>((ref) {
  return 0.0;
});

final StateProvider<String> amountInputStringProvider = StateProvider<String>((ref) {
  return "";
});
