import 'package:bdk_flutter/bdk_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/electrum_fallback.dart';

const _customFallbackKey = 'custom_fallback_enabled';

Future<Blockchain> _createBlockchain(String url, {int retry = 2, int timeout = 15}) {
  final config = BlockchainConfig.electrum(
    config: ElectrumConfig(
      url: url,
      retry: retry,
      stopGap: BigInt.from(20),
      validateDomain: false,
      timeout: timeout,
    ),
  );
  return Blockchain.create(config: config);
}

final blockchainProvider = Provider<TaskEither<String, Blockchain>>((ref) {
  final futPrefs = Task(() => SharedPreferences.getInstance());

  return TaskEither.tryCatch(() async {
    final prefs = await futPrefs.run();
    final customUrl = prefs.getString('bitcoin_node_url');
    // Defaults to true to preserve the prior behavior (custom URL = single
    // attempt). The user can opt into "custom URL with rotation" via the
    // node configuration screen.
    final customFallbackEnabled = prefs.getBool(_customFallbackKey) ?? true;

    if (customUrl != null && customUrl.isNotEmpty) {
      // Custom URL + fallback OFF: single attempt, current behavior preserved.
      if (!customFallbackEnabled) {
        debugPrint(
          '[BlockchainProvider] Using custom Bitcoin node (no fallback): $customUrl',
        );
        return await _createBlockchain(customUrl, retry: 3, timeout: 20);
      }

      // Custom URL + fallback ON: try the user's node first, then walk the
      // built-in list on failure.
      debugPrint(
        '[BlockchainProvider] Using custom Bitcoin node with fallback: $customUrl',
      );
      try {
        final blockchain = await _createBlockchain(customUrl, retry: 2, timeout: 15);
        return blockchain;
      } catch (e) {
        debugPrint(
          '[BlockchainProvider] Custom node failed, walking fallback list: $e',
        );
        // Fall through to the rotation loop below.
      }
    }

    // Default mode (or custom-with-fallback after the user node failed):
    // iterate the built-in server list with retry.
    int maxAttempts = 3;
    String? lastError;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final serverUrl = BitcoinElectrumFallback.getCurrentServer();
      debugPrint(
        '[BlockchainProvider] Tentativa ${attempt + 1}/$maxAttempts com servidor: $serverUrl',
      );

      try {
        final blockchain = await _createBlockchain(serverUrl, retry: 2, timeout: 15);

        BitcoinElectrumFallback.reportSuccess();
        debugPrint(
          '[BlockchainProvider] Conectado com sucesso ao servidor: $serverUrl',
        );
        return blockchain;
      } catch (e) {
        lastError = e.toString();
        debugPrint(
          '[BlockchainProvider] Falha na tentativa ${attempt + 1}: $lastError',
        );

        final shouldSwitch = BitcoinElectrumFallback.reportFailure(lastError);

        if (shouldSwitch && attempt < maxAttempts - 1) {
          final newServer = BitcoinElectrumFallback.switchToNextServer();
          debugPrint(
            '[BlockchainProvider] Tentando próximo servidor: $newServer',
          );
        }

        if (attempt < maxAttempts - 1) {
          await Future.delayed(Duration(seconds: 1 + attempt));
        }
      }
    }

    throw Exception(
      'Falha ao conectar aos servidores Bitcoin Electrum após $maxAttempts tentativas. Último erro: $lastError',
    );
  }, (err, _) => err.toString());
});
