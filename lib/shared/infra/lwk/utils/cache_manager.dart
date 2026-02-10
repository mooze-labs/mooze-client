import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';

class LwkCacheManager {
  static bool _hasAttemptedCleanup = false;
  static bool _cacheWasCleared = false;

  static void resetCleanupFlag() {
    _hasAttemptedCleanup = false;
    debugPrint('[LwkCacheManager] Flag de limpeza resetada');
  }

  static bool get cacheWasCleared => _cacheWasCleared;

  static void resetCacheClearedFlag() {
    _cacheWasCleared = false;
    debugPrint('[LwkCacheManager] Flag de cache limpo resetada');
  }

  static Future<void> clearLwkDatabase() async {
    try {
      debugPrint(
        '[LwkCacheManager] Iniciando limpeza do banco de dados LWK...',
      );

      final localDir = await getApplicationSupportDirectory();
      final dbPath = "${localDir.path}/lwk-db";
      final dir = Directory(dbPath);

      if (await dir.exists()) {
        debugPrint('[LwkCacheManager] Removendo diretório: $dbPath');
        await dir.delete(recursive: true);
        debugPrint('[LwkCacheManager] Diretório removido com sucesso');
      } else {
        debugPrint('[LwkCacheManager] Diretório não existe, nada para limpar');
      }

      debugPrint('[LwkCacheManager] Recriando diretório limpo...');
      await dir.create(recursive: true);
      _cacheWasCleared = true;
      debugPrint('[LwkCacheManager] Banco de dados LWK limpo com sucesso');
    } catch (e) {
      debugPrint('[LwkCacheManager] Erro ao limpar banco de dados: $e');
      rethrow;
    }
  }

  static Future<void> clearAndRestart() async {
    if (_hasAttemptedCleanup) {
      debugPrint(
        '[LwkCacheManager] Já tentou limpar nesta sessão, evitando loop infinito',
      );
      return;
    }

    _hasAttemptedCleanup = true;

    try {
      debugPrint(
        '[LwkCacheManager] Limpando banco de dados e reiniciando app...',
      );

      await clearLwkDatabase();

      debugPrint('[LwkCacheManager] Reiniciando aplicativo...');
      await Restart.restartApp(
        notificationTitle: "Reinicializando aplicativo",
        notificationBody:
            "Um problema foi detectado no Liquid. O cache será resetado e o aplicativo reiniciará.",
      );
    } catch (e) {
      debugPrint('[LwkCacheManager] Erro crítico ao limpar e reiniciar: $e');
      try {
        await clearLwkDatabase();
      } catch (cleanError) {
        debugPrint('[LwkCacheManager] Falha ao limpar: $cleanError');
      }
    }
  }

  static Future<bool> databaseExists() async {
    try {
      final localDir = await getApplicationSupportDirectory();
      final dbPath = "${localDir.path}/lwk-db";
      final dir = Directory(dbPath);
      return await dir.exists();
    } catch (e) {
      debugPrint('[LwkCacheManager] Erro ao verificar banco de dados: $e');
      return false;
    }
  }

  static Future<int> getDatabaseSize() async {
    try {
      final localDir = await getApplicationSupportDirectory();
      final dbPath = "${localDir.path}/lwk-db";
      final dir = Directory(dbPath);

      if (!await dir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('[LwkCacheManager] Erro ao calcular tamanho: $e');
      return 0;
    }
  }
}
