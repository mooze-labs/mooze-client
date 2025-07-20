import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/authentication/providers/signature_client_provider.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import '../services.dart';

const String baseUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: 'https://api.mooze.app/v1',
);

final userServiceProvider = FutureProvider<Either<String, UserService>>((
  ref,
) async {
  final authHttpClient = ref.watch(authenticatedClientProvider(baseUrl));
  final signatureClient = await ref.watch(signatureClientProvider.future);

  return await signatureClient.fold((error) => Left(error), (client) async {
    return await client
        .getPublicKey()
        .map((pubKey) => UserServiceImpl(authHttpClient, pubKey))
        .run();
  });
});
