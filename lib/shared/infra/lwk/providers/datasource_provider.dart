import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';

import 'package:mooze_mobile/shared/key_management/providers/mnemonic_store_provider.dart';

import '../wallet/datasource.dart';
import '../utils/cache_manager.dart';
import 'package:lwk/lwk.dart';
import 'package:path_provider/path_provider.dart';
import 'electrum_node_provider.dart';
import 'network_provider.dart';

final liquidDataSourceProvider = FutureProvider<
  Either<String, LiquidDataSource>
>((ref) async {
  final electrumNodeUrl = ref.read(electrumNodeProvider);
  final network = ref.read(networkProvider);
  final mnemonic = ref.read(mnemonicStoreProvider).getMnemonic();

  final TaskEither<String, String> descriptor = mnemonic.flatMap(
    (mnemonicOption) => mnemonicOption.fold(
      () => TaskEither<String, String>.left("Mnemonic has not been defined."),
      (mnemonic) => deriveNewDescriptorFromMnemonic(
        mnemonic,
        network,
      ).flatMap((descriptor) => TaskEither.right(descriptor.ctDescriptor)),
    ),
  );
  return descriptor.flatMap((descriptorStr) {
    final supportDir = TaskEither.tryCatch(
      () async => getApplicationSupportDirectory(),
      (error, stackTrace) => error.toString(),
    ).flatMap((dir) => TaskEither.right("${dir.path}/lwk-db"));

    final liquidDescriptor = TaskEither.fromEither(
      Either.tryCatch(
        () => Descriptor(ctDescriptor: descriptorStr),
        (error, stackTrace) => error.toString(),
      ),
    );

    return liquidDescriptor.flatMap(
      (desc) => supportDir.flatMap(
        (dbpath) => TaskEither.tryCatch(() async {
          try {
            final wallet = await Wallet.init(
              network: network,
              dbpath: dbpath,
              descriptor: desc,
            );

            debugPrint('[LWK] Wallet inicializado com sucesso');
            return wallet;
          } catch (error) {
            debugPrint('[LWK] Erro na inicialização do LWK: $error');
            debugPrint(
              '[LWK] Detectada corrupção do banco de dados. Limpando e reiniciando app...',
            );

            LwkCacheManager.clearAndRestart();

            await Future.delayed(const Duration(seconds: 1));

            rethrow;
          }
        }, (error, stackTrace) => error.toString()).flatMap(
          (wallet) => electrumNodeUrl.flatMap(
            (url) => TaskEither<String, LiquidDataSource>.right(
              LiquidDataSource(
                wallet: wallet,
                electrumUrl: url,
                network: network,
                validateDomain: true,
                descriptor: descriptorStr,
                dbPath: dbpath,
              ),
            ),
          ),
        ),
      ),
    );
  }).run();
});
