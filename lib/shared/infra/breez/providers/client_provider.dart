import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:fpdart/fpdart.dart';

import '../../../key_management/providers/mnemonic_provider.dart';
import 'config_provider.dart';

final breezClientProvider = FutureProvider<Either<String, BindingLiquidSdk>>((
  ref,
) async {
  final config = ref.watch(configProvider);
  final mnemonicOption = await ref.watch(mnemonicProvider.future);

  return mnemonicOption.fold(() => left('Mnemonic not available'), (
    mnemonic,
  ) async {
    try {
      final connectRequest = ConnectRequest(mnemonic: mnemonic, config: config);

      final client = await connect(req: connectRequest);
      return right(client);
    } catch (e) {
      return left('Failed to connect to Breez SDK: ${e.toString()}');
    }
  });
});
