import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/authentication/providers/session_manager_service_provider.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/sync_error_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';

final ensureAuthSessionProvider = FutureProvider<bool>((ref) async {
  final mnemonicOption = await ref.watch(mnemonicProvider.future);

  return mnemonicOption.fold(
    () {
      ref.read(syncErrorProvider.notifier).state = true;
      ref.read(syncErrorMessageProvider.notifier).state =
          'Mnemônico não encontrado';
      return false;
    },
    (mnemonic) async {
      final sessionManager = ref.read(sessionManagerServiceProvider);

      final sessionResult = await sessionManager.getSession().run();

      return sessionResult.fold(
        (error) async {
          await sessionManager.deleteSession().run();

          final newSessionResult = await sessionManager.getSession().run();

          return newSessionResult.fold(
            (createError) {
              final isServerError =
                  createError.contains('500') ||
                  createError.contains('502') ||
                  createError.contains('503') ||
                  createError.contains('504') ||
                  createError.toLowerCase().contains('server error') ||
                  createError.toLowerCase().contains('service unavailable');

              if (isServerError) {
                ref.read(apiDownProvider.notifier).state = true;
                final statusMatch = RegExp(
                  r'\b(5\d{2})\b',
                ).firstMatch(createError);
                if (statusMatch != null) {
                  ref.read(apiStatusCodeProvider.notifier).state = int.tryParse(
                    statusMatch.group(1)!,
                  );
                }
                ref.read(syncErrorProvider.notifier).state = false;
              } else {
                ref.read(syncErrorProvider.notifier).state = true;
                ref.read(syncErrorMessageProvider.notifier).state = createError;
                ref.read(apiDownProvider.notifier).state = false;
              }

              return false;
            },
            (newSession) {
              ref.read(syncErrorProvider.notifier).state = false;
              ref.read(syncErrorMessageProvider.notifier).state = null;
              ref.read(apiDownProvider.notifier).state = false;
              ref.read(apiStatusCodeProvider.notifier).state = null;
              return true;
            },
          );
        },
        (session) {
          ref.read(syncErrorProvider.notifier).state = false;
          ref.read(syncErrorMessageProvider.notifier).state = null;
          ref.read(apiDownProvider.notifier).state = false;
          ref.read(apiStatusCodeProvider.notifier).state = null;
          return true;
        },
      );
    },
  );
});

final refreshAuthSessionProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final sessionManager = ref.read(sessionManagerServiceProvider);

  final currentSessionResult = await sessionManager.getSession().run();

  return currentSessionResult.fold(
    (error) async {
      final newSessionResult = await sessionManager.getSession().run();
      return newSessionResult.isRight();
    },
    (currentSession) async {
      final refreshResult =
          await sessionManager.refreshSession(currentSession).run();

      return refreshResult.fold(
        (error) {
          return false;
        },
        (refreshedSession) async {
          await sessionManager.saveSession(refreshedSession).run();
          return true;
        },
      );
    },
  );
});
