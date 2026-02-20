import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:mooze_mobile/shared/key_management/providers/mnemonic_store_provider.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_stream_controller.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

import '../wallet/datasource.dart';
import '../utils/cache_manager.dart';
import '../utils/liquid_electrum_fallback.dart';
import 'package:lwk/lwk.dart';
import 'package:path_provider/path_provider.dart';
import 'electrum_node_provider.dart';
import 'network_provider.dart';

final liquidDataSourceProvider = FutureProvider<
  Either<String, LiquidDataSource>
>((ref) async {
  // Reset fallback to start from first server on each provider recreation
  LiquidElectrumFallback.reset();
  debugPrint(
    '[LiquidDataSourceProvider] Fallback reset - starting from first server',
  );

  final electrumNodeUrl = ref.read(electrumNodeProvider);
  final network = ref.read(networkProvider);
  final mnemonic = ref.read(mnemonicStoreProvider).getMnemonic();
  final syncStream = ref.read(syncStreamProvider);
  final database = ref.read(appDatabaseProvider);

  debugPrint(
    '[LiquidDataSourceProvider] Using SyncStreamController hashCode: ${syncStream.hashCode}',
  );

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
      (error, stackTrace) =>
          'Failed to get application support directory: ${error.toString()}',
    ).flatMap((dir) => TaskEither.right("${dir.path}/lwk-db"));

    final liquidDescriptor = TaskEither.fromEither(
      Either.tryCatch(() => Descriptor(ctDescriptor: descriptorStr), (
        error,
        stackTrace,
      ) {
        return 'Failed to create Descriptor: ${error.toString()}';
      }),
    );

    return liquidDescriptor.flatMap(
      (desc) => supportDir.flatMap(
        (dbpath) => TaskEither.tryCatch(() async {
          try {
            final dbDir = Directory(dbpath);

            if (!await dbDir.exists()) {
              await dbDir.create(recursive: true);
            } else {
              await dbDir.list().toList();
            }

            await dbDir.stat();

            final wallet = await Wallet.init(
              network: network,
              dbpath: dbpath,
              descriptor: desc,
            );

            return wallet;
          } catch (error) {
            String errorMessage =
                (error is LwkError)
                    ? 'LwkError: ${error.msg}'
                    : error.toString();
            final errorStr = errorMessage.toLowerCase();

            final isCorruption =
                (errorStr.contains('database') &&
                    (errorStr.contains('corrupt') ||
                        errorStr.contains('malform') ||
                        errorStr.contains('not a database'))) ||
                errorStr.contains('updateondifferentstatus') ||
                (errorStr.contains('persisterror') &&
                    errorStr.contains('notfound'));

            if (isCorruption) {
              await LwkCacheManager.clearLwkDatabase();

              if (errorStr.contains('updateondifferentstatus') ||
                  errorStr.contains('persisterror')) {
                try {
                  final wallet = await Wallet.init(
                    network: network,
                    dbpath: dbpath,
                    descriptor: desc,
                  );
                  return wallet;
                } catch (retryError) {
                  rethrow;
                }
              }
            }

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
                syncStream: syncStream,
                database: database,
                ref: ref, // Adiciona ref aqui
              ),
            ),
          ),
        ),
      ),
    );
  }).run();
});
