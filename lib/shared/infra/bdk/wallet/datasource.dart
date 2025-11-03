import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_service.dart';

const String mnemonicKey = 'mnemonic';
const String wpkhExternalDerivationPath = "m/84h/0h/0h/0";
const String wpkhInternalDerivationPath = "m/84h/1h/1h/0";

@override
class BdkDataSource implements SyncableDataSource {
  final Wallet wallet;
  final Blockchain blockchain;

  BdkDataSource({required this.wallet, required this.blockchain});

  @override
  Future<void> sync() async {
    debugPrint("[BdkDataSource] Syncing");
    await wallet.sync(blockchain: blockchain);
  }
}

TaskEither<String, Wallet> setupWallet(String mnemonicStr, Network network) {
  final mnemonic = TaskEither.tryCatch(
    () async => Mnemonic.fromString(mnemonicStr),
    (err, _) => err.toString(),
  );

  final descriptor = mnemonic.flatMap(
    (m) => deriveDescriptor(m, network, wpkhExternalDerivationPath),
  );
  final changeDescriptor = mnemonic.flatMap(
    (m) => deriveDescriptor(m, network, wpkhInternalDerivationPath),
  );

  final wallet = descriptor.flatMap(
    (d) => changeDescriptor.flatMap(
      (c) => TaskEither.tryCatch(
        () async => await Wallet.create(
          descriptor: d,
          changeDescriptor: c,
          network: network,
          databaseConfig: const DatabaseConfig.memory(),
        ),
        (err, _) => err.toString(),
      ),
    ),
  );

  return wallet;
}

TaskEither<String, Descriptor> deriveDescriptor(
  Mnemonic mnemonic,
  Network network,
  String derivationPath,
) {
  final derivationPath = _derivePath(wpkhExternalDerivationPath);
  final descriptorSecretKey = _createSecretKey(network, mnemonic);

  final secretDerivationPath = derivationPath.flatMap(
    (derivationPath) => descriptorSecretKey.flatMap(
      (descSecretKey) => _deriveSecretPath(descSecretKey, derivationPath),
    ),
  );

  final externalPrivateDescriptor = secretDerivationPath.flatMap(
    (derivPath) => _createDescriptor("wpkh(${derivPath.toString()})", network),
  );

  return externalPrivateDescriptor;
}

TaskEither<String, Descriptor> _createDescriptor(
  String descriptor,
  Network network,
) => TaskEither.tryCatch(
  () async => await Descriptor.create(descriptor: descriptor, network: network),
  (err, _) => err.toString(),
);

TaskEither<String, DescriptorSecretKey> _createSecretKey(
  Network network,
  Mnemonic mnemonic,
) => TaskEither.tryCatch(
  () async =>
      await DescriptorSecretKey.create(network: network, mnemonic: mnemonic),
  (err, _) => err.toString(),
);

TaskEither<String, DescriptorSecretKey> _deriveSecretPath(
  DescriptorSecretKey key,
  DerivationPath path,
) => TaskEither.tryCatch(
  () async => key.derive(path),
  (err, _) => err.toString(),
);

TaskEither<String, DerivationPath> _derivePath(String path) =>
    TaskEither.tryCatch(
      () async => DerivationPath.create(path: path),
      (err, _) => err.toString(),
    );
