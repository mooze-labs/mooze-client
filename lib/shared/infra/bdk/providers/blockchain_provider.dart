import 'package:bdk_flutter/bdk_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/electrum_fallback.dart';

final blockchainProvider = Provider<TaskEither<String, Blockchain>>((ref) {
  final futPrefs = Task(() => SharedPreferences.getInstance());

  return TaskEither.tryCatch(() async {
    final prefs = await futPrefs.run();
    final customUrl = prefs.getString('bitcoin_node_url');

    // Use custom URL if available, fallback disabled when custom URL is set
    if (customUrl != null) {
      debugPrint('[BlockchainProvider] Using custom Bitcoin node: $customUrl');
      final config = BlockchainConfig.electrum(
        config: ElectrumConfig(
          url: customUrl,
          retry: 3,
          stopGap: BigInt.from(20),
          validateDomain: false,
          timeout: 20,
        ),
      );
      return await Blockchain.create(config: config);
    }

    // Try with fallback servers
    int maxAttempts = 3;
    String? lastError;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final serverUrl = BitcoinElectrumFallback.getCurrentServer();
      debugPrint(
        '[BlockchainProvider] Tentativa ${attempt + 1}/$maxAttempts com servidor: $serverUrl',
      );

      try {
        final config = BlockchainConfig.electrum(
          config: ElectrumConfig(
            url: serverUrl,
            retry: 2,
            stopGap: BigInt.from(20),
            validateDomain: false,
            timeout: 15,
          ),
        );

        final blockchain = await Blockchain.create(config: config);

        // Success! Report it and return
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

        // Report failure and check if we should switch servers
        final shouldSwitch = BitcoinElectrumFallback.reportFailure(lastError);

        if (shouldSwitch && attempt < maxAttempts - 1) {
          final newServer = BitcoinElectrumFallback.switchToNextServer();
          debugPrint(
            '[BlockchainProvider] Tentando próximo servidor: $newServer',
          );
        }

        // If not the last attempt, wait a bit before retrying
        if (attempt < maxAttempts - 1) {
          await Future.delayed(Duration(seconds: 1 + attempt));
        }
      }
    }

    // All attempts failed
    throw Exception(
      'Falha ao conectar aos servidores Bitcoin Electrum após $maxAttempts tentativas. Último erro: $lastError',
    );
  }, (err, _) => err.toString());
});
