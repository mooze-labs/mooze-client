import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/remote_auth_service.dart';
import '../services/remote_auth_service_impl.dart';

Provider<RemoteAuthenticationService> remoteAuthServiceWithMnemonicProvider(
  String mnemonic,
) {
  return Provider<RemoteAuthenticationService>(
    (ref) => RemoteAuthServiceImpl.withEcdsaClient(mnemonic),
  );
}
