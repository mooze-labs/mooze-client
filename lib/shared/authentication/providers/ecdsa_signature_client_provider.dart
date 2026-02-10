import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/authentication/clients/ecdsa_signature_client.dart';
import 'package:mooze_mobile/shared/authentication/clients/signature_client.dart';

final ecdsaSignatureClientProvider = FutureProvider<SignatureClient>((
  ref,
) async {
  final mnemonicOption = await ref.watch(mnemonicProvider.future);

  final mnemonic = mnemonicOption.fold(
    () =>
        throw Exception(
          'Mnemonic não encontrado. Usuário precisa configurar uma carteira primeiro.',
        ),
    (mnemonic) => mnemonic,
  );

  return EcdsaSignatureClient(userSeed: mnemonic);
});

Provider<SignatureClient> ecdsaSignatureClientWithMnemonicProvider(
  String mnemonic,
) {
  return Provider<SignatureClient>(
    (ref) => EcdsaSignatureClient(userSeed: mnemonic),
  );
}
