import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../clients/signature_client.dart';
import '../clients/ecdsa_signature_client.dart';
import '../../key_management/providers/mnemonic_provider.dart';

final signatureClientProvider = FutureProvider<Either<String, SignatureClient>>(
  (ref) async {
    final mnemonicOption = await ref.watch(mnemonicProvider.future);
    return mnemonicOption.fold(
      () => Either.left('Mnemonic não encontrado'),
      (mnemonic) => Either.right(
        EcdsaSignatureClient(userSeed: mnemonic) as SignatureClient,
      ),
    );
  },
);
