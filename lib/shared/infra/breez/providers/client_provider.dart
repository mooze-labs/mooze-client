import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:fpdart/fpdart.dart';

import '../../../key_management/providers/mnemonic_provider.dart';
import 'config_provider.dart';

final breezClientProvider = FutureProvider<Either<String, BreezSdkLiquid>>((
  ref,
) async {
  final config = await ref.read(configProvider.future);
  final mnemonicOption = await ref.watch(mnemonicProvider.future);

  return await mnemonicOption.fold(() async => left('Mnemonic not available'), (
    mnemonic,
  ) async {
    try {
      final connectRequest = ConnectRequest(mnemonic: mnemonic, config: config);

      final client = await connect(req: connectRequest);
      return right(client);
    } catch (e) {
      final errorMessage = e.toString();

      if (errorMessage.contains('rusqlite_migrate') ||
          errorMessage.contains('duplicate column name')) {
        try {
          final dbDir = Directory(config.workingDir);
          if (await dbDir.exists()) {
            await dbDir.delete(recursive: true);
          }

          final retryRequest = ConnectRequest(
            mnemonic: mnemonic,
            config: config,
          );
          final client = await connect(req: retryRequest);
          return right(client);
        } catch (retryError) {
          return left(
            'Failed to connect to Breez SDK after database cleanup: ${retryError.toString()}',
          );
        }
      }

      return left('Failed to connect to Breez SDK: $errorMessage');
    }
  });
});
