import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import '../entities/address_match.dart';
import '../entities/address_utxo.dart';
import '../entities/wallet_address.dart';

/// Domain contract for address & UTXO inspection across chains.
///
/// Implementations live in the data layer and adapt the underlying SDKs
/// (BDK for Bitcoin; LWK + Breez SDK Liquid for Liquid) without leaking
/// SDK types upward.
abstract class AddressExplorerRepository {
  /// Returns wallet-derived Bitcoin addresses with their UTXOs and usage
  /// status. Implementations should respect [limit] as the maximum number
  /// of derivation indices to walk.
  TaskEither<WalletError, List<WalletAddress>> listBitcoinAddresses({
    int limit = 100,
  });

  /// Returns wallet-derived Liquid addresses with usage status. UTXOs are
  /// not exposed at this layer for Liquid (see [listLiquidUtxos]).
  TaskEither<WalletError, List<WalletAddress>> listLiquidAddresses({
    int limit = 100,
  });

  /// Returns all unspent outputs currently held by the Bitcoin wallet.
  TaskEither<WalletError, List<AddressUtxo>> listBitcoinUtxos();

  /// Returns the per-asset balance entries from the Liquid wallet as
  /// [AddressUtxo] proxies. Liquid SDKs do not expose individual UTXOs.
  TaskEither<WalletError, List<AddressUtxo>> listLiquidUtxos();

  /// Probes whether [address] belongs to the Bitcoin wallet. Returns
  /// [AddressMatch.notOwned] if not, or [AddressMatch.owned] otherwise.
  TaskEither<WalletError, AddressMatch> isOwnedBitcoinAddress(String address);

  /// Probes whether [address] belongs to the Liquid wallet (LWK descriptor
  /// match or Breez payment-history match).
  TaskEither<WalletError, AddressMatch> isOwnedLiquidAddress(String address);

  /// Fetches the next Bitcoin receive address that is verified to have no
  /// on-chain history. Implementations must walk the descriptor forward
  /// until an unused address is found, even if BDK's internal index points
  /// to a previously-used address (e.g. after a wallet restore).
  TaskEither<WalletError, WalletAddress> getNextUnusedBitcoinAddress();

  /// Fetches the next Liquid receive address (LWK addressLastUnused with
  /// a defensive history check).
  TaskEither<WalletError, WalletAddress> getNextUnusedLiquidAddress();
}
