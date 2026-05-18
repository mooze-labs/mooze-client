import 'package:lwk/lwk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';
import 'package:mooze_mobile/database/database.dart';

const String mnemonicKey = 'mnemonic_mainWallet';

/// Legacy LWK datasource. Reduced to a thin wallet-handle wrapper around
/// the V2-owned `lwk.Wallet` instance. Surviving callers
/// (`WalletRepositoryImpl/liquid.dart`, `address_explorer_repository_impl.dart`)
/// read [wallet] for balances, txs, addresses, and PSET signing.
///
/// V2 [LiquidWalletServiceImpl] is the sole owner of the wallet's
/// lifecycle (connect / sync / disconnect). This class never drives any
/// sync work — its `sync()` is a no-op preserved for legacy API
/// compatibility.
class LiquidDataSource {
  LiquidDataSource({
    required this.wallet,
    required this.network,
    required this.electrumUrl,
    required this.validateDomain,
    this.descriptor = '',
    this.dbPath = '',
    this.database,
    required this.ref,
    this.useFallback = true,
  });

  final Wallet wallet;
  final Network network;
  final String electrumUrl;
  final bool validateDomain;
  final String descriptor;
  final String dbPath;
  final AppDatabase? database;
  final Ref ref;
  final bool useFallback;

  /// No-op. V2 [SyncOrchestrator] is the only sync surface.
  Future<void> sync() async {}

  void syncInBackground() {}

  Future<String> getAddress() async {
    final address = await wallet.addressLastUnused();
    return address.confidential;
  }

  Future<String> signPset(String pset) async {
    final mnemonic =
        await SecureStorageProvider.instance.read(key: mnemonicKey);
    if (mnemonic == null) {
      throw Exception('Mnemonic not found');
    }
    return wallet.signedPsetWithExtraDetails(
      network: network,
      pset: pset,
      mnemonic: mnemonic,
    );
  }
}
