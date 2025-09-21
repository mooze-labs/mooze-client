import 'package:bdk_flutter/bdk_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String defaultElectrumUrl = "blockstream.info:110";

final blockchainProvider = Provider<TaskEither<String, Blockchain>>((ref) {
  final futPrefs = Task(() => SharedPreferences.getInstance());
  final electrumUrl = futPrefs.map(
    (prefs) => prefs.getString('bitcoin_node_url') ?? defaultElectrumUrl,
  );

  final config = electrumUrl.map(
    (url) => BlockchainConfig.electrum(
      config: ElectrumConfig(
        url: url,
        retry: 5,
        stopGap: BigInt.from(10),
        validateDomain: false,
        timeout: 5,
      ),
    ),
  );

  return TaskEither.tryCatch(
    () async => await Blockchain.create(config: await config.run()),
    (err, _) => err.toString(),
  );
});
