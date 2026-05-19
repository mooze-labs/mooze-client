import 'package:fpdart/fpdart.dart';

import '../failures/failure.dart';
import 'spendable_wallet_service.dart';
import 'wallet_service.dart';

/// BDK-backed on-chain Bitcoin service.
///
/// Implements [SpendableWalletService] for `ChainId.bitcoin` — the impl
/// dispatches on `SendRequest.chain` and rejects non-Bitcoin requests with
/// a typed [ServiceFailure]. There is no Lightning lane on this service;
/// Lightning lives on `LightningWalletService` (Breez Liquid SDK).
///
/// Lifecycle: BDK runs against a persistent sqlite store under the
/// `bdk-db` working directory (acquired via `WalletDirectoryGuard`,
/// same pattern as LWK / Breez). On connect, the wallet replays its
/// on-disk state and the service primes `_lastBalance` / `_lastList`
/// from local reads so the UI never sees a transient zero-balance
/// flash on cold start before the first electrum sync completes.
abstract interface class BitcoinWalletService
    implements WalletService, SpendableWalletService {
  /// Current Bitcoin chain tip height, fetched from the connected
  /// Electrum node. Used by tx-history UI to compute confirmations
  /// (`tip - txConfirmationHeight + 1`). Returns a typed failure if the
  /// Electrum query fails — UI should treat that as "confirmations
  /// unknown" and not block rendering.
  Future<Either<ServiceFailure, int>> getBlockHeight();
}
