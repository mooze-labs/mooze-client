import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/database/database.dart';

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
    required this.blockchain,
    required this.ref,
    this.database,
  });

  final Wallet wallet;
  final Blockchain blockchain;
  final Ref ref;
  final AppDatabase? database;

  /// No-op. V2 [SyncOrchestrator] is the only sync surface.
  Future<void> sync() async {}

  void syncInBackground() {}
}
