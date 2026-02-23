import 'package:flutter/foundation.dart';

class LiquidElectrumFallback {
  static final List<String> _servers = [
    'ssl://electrum.blockstream.info:465',
    'ssl://blockstream.info:465',
    'ssl://liquid.taxi:51002',
    'ssl://blockstream.info:995',
  ];

  static int _currentServerIndex = 0;
  static int _consecutiveFailures = 0;
  static DateTime? _lastFailure;

  static String getCurrentServer() {
    return _servers[_currentServerIndex];
  }

  static bool reportFailure(String errorMsg) {
    _consecutiveFailures++;
    _lastFailure = DateTime.now();

    final errorLower = errorMsg.toLowerCase();
    final isServerIssue =
        errorLower.contains('tls') ||
        errorLower.contains('ssl') ||
        errorLower.contains('close_notify') ||
        errorLower.contains('unexpectedeof') ||
        errorLower.contains('peer closed connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('allattempterserror') ||
        errorLower.contains('broken pipe') ||
        errorLower.contains('failed to lookup') ||
        errorLower.contains('no address associated') ||
        errorLower.contains('connection refused') ||
        errorLower.contains('connection reset') ||
        errorLower.contains('network unreachable') ||
        errorLower.contains('lwkerror') ||
        errorLower.contains('network error') ||
        errorLower.contains('alertreceived') ||
        errorLower.contains('decodeerror') ||
        errorLower.contains('invaliddata') ||
        errorLower.contains('os error 32') ||
        errorLower.contains('os error 54') ||
        errorLower.contains('os error 61');

    if (isServerIssue && _consecutiveFailures >= 1) {
      debugPrint(
        '[LiquidElectrumFallback] Detectadas $_consecutiveFailures falhas consecutivas. Trocando servidor...',
      );
      return true;
    }

    return false;
  }

  static String switchToNextServer() {
    final previousServer = _servers[_currentServerIndex];
    _currentServerIndex = (_currentServerIndex + 1) % _servers.length;
    _consecutiveFailures = 0;

    final newServer = _servers[_currentServerIndex];
    debugPrint(
      '[LiquidElectrumFallback] Trocando servidor: $previousServer → $newServer',
    );

    return newServer;
  }

  static void reportSuccess() {
    if (_consecutiveFailures > 0) {
      debugPrint(
        '[LiquidElectrumFallback] Sync bem-sucedido após $_consecutiveFailures falha(s). Resetando contador.',
      );
    }
    _consecutiveFailures = 0;
  }

  static String peekNextServer() {
    final nextIndex = (_currentServerIndex + 1) % _servers.length;
    return _servers[nextIndex];
  }

  static Map<String, dynamic> getStats() {
    return {
      'currentServer': getCurrentServer(),
      'consecutiveFailures': _consecutiveFailures,
      'lastFailure': _lastFailure?.toIso8601String(),
      'availableServers': _servers.length,
    };
  }

  @visibleForTesting
  static void reset() {
    _currentServerIndex = 0;
    _consecutiveFailures = 0;
    _lastFailure = null;
  }
}
