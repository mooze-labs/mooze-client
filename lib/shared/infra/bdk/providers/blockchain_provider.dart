import 'package:bdk_flutter/bdk_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/electrum_fallback.dart';

final blockchainProvider = Provider<TaskEither<String, Blockchain>>((ref) {
  final futPrefs = Task(() => SharedPreferences.getInstance());
  final electrumUrl = futPrefs.map((prefs) {
    final customUrl = prefs.getString('bitcoin_node_url');

    if (customUrl != null) {
      return customUrl;
    }

    return BitcoinElectrumFallback.getCurrentServer();
  });

  final config = electrumUrl.map(
    (url) => BlockchainConfig.electrum(
      config: ElectrumConfig(
        url: url,
        retry: 2,
        stopGap: BigInt.from(20),
        validateDomain: false,
        timeout: 15,
      ),
    ),
  );

  return TaskEither.tryCatch(
    () async => await Blockchain.create(config: await config.run()),
    (err, _) => err.toString(),
  );
});
