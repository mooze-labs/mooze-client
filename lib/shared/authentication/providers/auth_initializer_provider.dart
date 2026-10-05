import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart' show moozeCoreProvider;
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';

class AuthInitializer extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;

  AuthInitializer(this._ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('[AuthInitializer] Iniciando verificação de sessão...');
      }

      final sessionEnsured = await _ref.read(ensureAuthSessionProvider.future);

      if (sessionEnsured) {
        if (kDebugMode) {
          debugPrint('[AuthInitializer] Sessão JWT garantida');
        }
        state = const AsyncValue.data(true);
      } else {
        if (kDebugMode) {
          debugPrint('[AuthInitializer]  Não foi possível garantir sessão');
        }
        state = const AsyncValue.data(false);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[AuthInitializer] Erro ao inicializar auth: $e');
      }
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshSession() async {
    state = const AsyncValue.loading();
    try {
      if (kDebugMode) {
        debugPrint('[AuthInitializer] Forçando refresh de sessão...');
      }

      final core = await _ref.read(moozeCoreProvider.future);
      final ok = await core.authRefreshCurrent();
      if (kDebugMode) {
        debugPrint(ok
            ? '[AuthInitializer] Sessão refreshada com sucesso'
            : '[AuthInitializer] Erro ao refresh');
      }
      state = AsyncValue.data(ok);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[AuthInitializer] Erro ao refresh: $e');
      }
      state = AsyncValue.error(e, stack);
    }
  }
}

final authInitializerProvider =
    StateNotifierProvider<AuthInitializer, AsyncValue<bool>>((ref) {
      return AuthInitializer(ref);
    });
