import 'package:fpdart/fpdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lwk/lwk.dart';
import 'package:path_provider/path_provider.dart';

const String mnemonicKey = 'mnemonic';

class LiquidDataSource {
  final Wallet wallet;
  final Network network;
  final String electrumUrl;
  final bool validateDomain;

  LiquidDataSource({
    required this.wallet,
    required this.network,
    required this.electrumUrl,
    required this.validateDomain,
  });

  Future<void> sync() async {
    await wallet.sync_(
      electrumUrl: electrumUrl,
      validateDomain: validateDomain,
    );
  }

  Future<String> getAddress() async {
    final address = await wallet.addressLastUnused();
    return address.confidential;
  }

  Future<String> signPset(String pset) async {
    final mnemonic = await FlutterSecureStorage().read(key: mnemonicKey);

    if (mnemonic == null) {
      throw Exception('Mnemonic not found');
    }

    final signedPset = await wallet.signedPsetWithExtraDetails(
      network: network,
      pset: pset,
      mnemonic: mnemonic,
    );

    return signedPset;
  }
}

TaskEither<String, Descriptor> deriveNewDescriptorFromMnemonic(
  String mnemonic,
  Network network,
) {
  return TaskEither.tryCatch(
    () async =>
        Descriptor.newConfidential(network: network, mnemonic: mnemonic),
    (error, stacktrace) => error.toString(),
  );
}

TaskEither<String, Wallet> initializeNewWallet(
  String descriptor,
  Network network,
) {
  final supportDir = TaskEither.tryCatch(
    () async => getApplicationSupportDirectory(),
    (error, stackTrace) => error.toString(),
  ).flatMap((dir) => TaskEither.right("${dir.path}/lwk-db"));

  final liquidDescriptor = TaskEither.fromEither(
    Either.tryCatch(
      () => Descriptor(ctDescriptor: descriptor),
      (error, stackTrace) => error.toString(),
    ),
  );

  return liquidDescriptor.flatMap(
    (desc) => supportDir.flatMap(
      (dbpath) => TaskEither.tryCatch(() async {
        return await Wallet.init(
          network: network,
          dbpath: dbpath,
          descriptor: desc,
        );
      }, (error, stackTrace) => error.toString()),
    ),
  );
}

