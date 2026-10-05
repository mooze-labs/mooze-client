import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart' show moozeCoreProvider;
import 'package:mooze_mobile/infra/core/core_dto_mapper.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/sync_error_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';

/// Boot-time session check. mooze-core signs in with the stored mnemonic
/// if needed. The result sets the sync-error and API-down flags.
final ensureAuthSessionProvider = FutureProvider<bool>((ref) async {
  // Watch the mnemonic so a new wallet runs the check again.
  final mnemonicOption = await ref.watch(mnemonicProvider.future);
  if (mnemonicOption.isNone()) {
    _setMissingMnemonic(ref);
    return false;
  }

  final AuthEnsureDto result;
  try {
    final core = await ref.read(moozeCoreProvider.future);
    result = await core.authEnsureSession();
  } catch (e) {
    _setFailed(ref, e is CoreError ? coreErrorMessage(e) : '$e');
    return false;
  }

  switch (result.kind) {
    case AuthEnsureKind.ready:
      ref.read(syncErrorProvider.notifier).state = false;
      ref.read(syncErrorMessageProvider.notifier).state = null;
      ref.read(apiDownProvider.notifier).state = false;
      ref.read(apiStatusCodeProvider.notifier).state = null;
      return true;
    case AuthEnsureKind.missingMnemonic:
      _setMissingMnemonic(ref);
      return false;
    case AuthEnsureKind.apiDown:
      ref.read(apiDownProvider.notifier).state = true;
      if (result.statusCode != null) {
        ref.read(apiStatusCodeProvider.notifier).state = result.statusCode;
      }
      ref.read(syncErrorProvider.notifier).state = false;
      return false;
    case AuthEnsureKind.failed:
      _setFailed(ref, result.message ?? 'Falha ao autenticar');
      return false;
  }
});

void _setMissingMnemonic(Ref ref) {
  ref.read(syncErrorProvider.notifier).state = true;
  ref.read(syncErrorMessageProvider.notifier).state = 'Mnemônico não encontrado';
}

void _setFailed(Ref ref, String message) {
  ref.read(syncErrorProvider.notifier).state = true;
  ref.read(syncErrorMessageProvider.notifier).state = message;
  ref.read(apiDownProvider.notifier).state = false;
}

/// Manual session refresh. Returns success.
final refreshAuthSessionProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  try {
    final core = await ref.read(moozeCoreProvider.future);
    return await core.authRefreshCurrent();
  } catch (_) {
    return false;
  }
});
