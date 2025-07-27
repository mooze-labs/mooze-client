import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lwk/lwk.dart';

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
