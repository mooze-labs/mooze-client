import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/electrum_fallback.dart';

final electrumNodeProvider = Provider<TaskEither<String, String>>((ref) {
  return TaskEither.tryCatch(() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final customUrl = sharedPrefs.getString('liquid_node_url');

    if (customUrl != null) {
      return customUrl;
    }

    return LiquidElectrumFallback.getCurrentServer();
  }, (error, stackTrace) => LiquidElectrumFallback.getCurrentServer());
});
