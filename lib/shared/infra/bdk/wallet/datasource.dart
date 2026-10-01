import 'package:bdk_dart/bdk_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/infra/bdk/bdk_electrum.dart';

/// Legacy BDK datasource. Reduced to a thin wallet-handle wrapper around
/// the V2-owned `bdk.Wallet` instance. Surviving callers
/// (`WalletRepositoryImpl/bitcoin.dart`, `address_explorer_repository_impl.dart`)
/// read [wallet] for tx listing and PSBT construction.
///
/// V2 [BitcoinWalletServiceImpl] is the sole owner of the wallet's
/// lifecycle (connect / sync / disconnect). This class never drives any
/// sync work — its `sync()` is a no-op preserved for legacy API
/// compatibility.
class BdkDataSource {
  BdkDataSource({
    required this.wallet,
    required this.electrum,
    required this.persist,
    required this.ref,
    this.database,
  });

  final Wallet wallet;
  final BdkElectrum electrum;

  /// Writes staged wallet changes (for example, revealed addresses) to the
  /// V2 service's sqlite store. Call it after any call that changes the
  /// wallet.
  final void Function() persist;
  final Ref ref;
  final AppDatabase? database;

  /// No-op. V2 [SyncOrchestrator] is the only sync surface.
  Future<void> sync() async {}

  void syncInBackground() {}
}
