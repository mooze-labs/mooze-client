import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _defaultNodeUrl = String.fromEnvironment(
  "LIQUID_DEFAULT_NODE",
  defaultValue: "blockstream.info:995",
);

final electrumNodeProvider = Provider<TaskEither<String, String>>((ref) {
  return TaskEither.tryCatch(() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    return sharedPrefs.getString('liquid_node_url') ?? _defaultNodeUrl;
  }, (error, stackTrace) => _defaultNodeUrl);
});
