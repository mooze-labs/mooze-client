import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../clients/signature_client.dart';
import '../clients/signature_client_impl.dart';
import '../../infra/breez/providers.dart';

final signatureClientProvider = FutureProvider<Either<String, SignatureClient>>(
  (ref) async {
    final breezClient = await ref.watch(breezClientProvider.future);
    return breezClient.flatMap(
      (client) => Either.right(BreezSignatureClient(client)),
    );
  },
);
