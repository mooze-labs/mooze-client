import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:fpdart/fpdart.dart';

import 'signature_client.dart';

class BreezSignatureClient implements SignatureClient {
  final BreezSdkLiquid _breez;

  BreezSignatureClient(this._breez);

  @override
  Either<String, String> signMessage(String message) {
    final signMessageRequest = SignMessageRequest(message: message);
    final signMessageResponse = Either.tryCatch(
      () => _breez.signMessage(req: signMessageRequest).signature,
      (error, stackTrace) => error.toString(),
    );

    return signMessageResponse;
  }

  @override
  TaskEither<String, String> getPublicKey() {
    return TaskEither.tryCatch(() async {
      final info = await _breez.getInfo();
      return info.walletInfo.pubkey;
    }, (error, stackTrace) => error.toString());
  }
}
