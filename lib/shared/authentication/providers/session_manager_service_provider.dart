import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/authentication/services/remote_auth_service_impl.dart';

import '../services/session_manager_service.dart';
import '../services/session_manager_service_impl.dart';
import 'remote_auth_service_provider.dart';

final sessionManagerServiceProvider = Provider<SessionManagerService>((ref) {
  final secureStorage = FlutterSecureStorage();

  final mnemonicAsync = ref.watch(mnemonicProvider);

  return mnemonicAsync.maybeWhen(
    data: (mnemonicOption) {
      return mnemonicOption.fold(
        () => SessionManagerServiceImpl(secureStorage: secureStorage),
        (mnemonic) => SessionManagerServiceImpl(
          secureStorage: secureStorage,
          remoteAuthService: RemoteAuthServiceImpl.withEcdsaClient(mnemonic),
        ),
      );
    },
    orElse: () => SessionManagerServiceImpl(secureStorage: secureStorage),
  );
});

Provider<SessionManagerService> sessionWithAuthProvider(String mnemonic) {
  return Provider<SessionManagerService>((ref) {
    final secureStorage = FlutterSecureStorage();
    final remoteAuthService = ref.read(
      remoteAuthServiceWithMnemonicProvider(mnemonic),
    );

    return SessionManagerServiceImpl(
      secureStorage: secureStorage,
      remoteAuthService: remoteAuthService,
    );
  });
}
