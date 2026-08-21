import 'package:fpdart/fpdart.dart';

import '../entities/balance.dart';
import '../entities/liquid_send_draft.dart';
import '../entities/liquid_utxo.dart';
import '../failures/failure.dart';
import 'wallet_service.dart';

/// LWK-backed Liquid service.
///
/// Beyond the read surface inherited from [WalletService] (sync,
/// balance, transactions, list), this service exposes the swap-only
/// capabilities that legacy `LiquidDataSource` had: PSET signing for
/// SideSwap PayJoins and UTXO enumeration. These are intentionally
/// here (not on `LightningWalletService`) because LWK is the only V2
/// service that holds the Liquid descriptor private keys — Breez
/// Liquid SDK doesn't expose raw PSET signing.
///
abstract interface class LiquidWalletService implements WalletService {
  /// Enumerate the wallet's spendable UTXOs as V2 domain types. Used by
  /// the swap flow to select inputs for SideSwap-style PayJoin
  /// transactions.
  ///
  /// Returns the full unblinded set — callers filter by asset and
  /// amount themselves. Empty list if the wallet has no UTXOs.
  Future<Either<ServiceFailure, List<LiquidUtxo>>> getUtxos();

  /// Sign a pre-built PSET (Partially Signed Elements Transaction)
  /// using the wallet's mnemonic. Used by the SideSwap flow: the
  /// server constructs the PSET, the wallet signs its own inputs and
  /// returns the signed PSET for server-side broadcast.
  ///
  /// [mnemonic] is supplied by the caller — the service does NOT cache
  /// it (matches V2's "no in-memory mnemonic state" invariant). The
  /// caller fetches it once from `SecureCredentialStore` per signing
  /// request.
  Future<Either<ServiceFailure, String>> signSwapPset({
    required String pset,
    required String mnemonic,
  });

  /// Next unused confidential Liquid address derived from the LWK
  /// descriptor. Used by the swap flow as the destination for swap
  /// proceeds — must come from LWK (not Breez) because the swap PSET
  /// is signed by LWK and the receive output has to be derivable from
  /// the same descriptor that produced the signing keys.
  Future<Either<ServiceFailure, String>> getReceiveAddress();

  Future<Either<ServiceFailure, LiquidSendDraft>> buildLbtcSend({
    required String destination,
    required BigInt amountSat,
    double? feeRateSatPerVb,
    bool drain = false,
  });

  Future<Either<ServiceFailure, String>> signAndBroadcastPset({
    required String pset,
    required String mnemonic,
  });

  /// Re-read LWK's local balance view (`w.balances()`) and update the
  /// cached `_lastBalance` WITHOUT running a full electrum sync. LWK
  /// holds balances in its persistent store, so this is essentially a
  /// hot cache refresh — cheap, never hits the network.
  Future<Either<ServiceFailure, Balance>> refreshBalance();

  /// Apply known per-asset deltas to the cached `_lastBalance` for
  /// instant UI feedback. Used after a SideSwap broadcast where the
  /// LWK electrum view has not yet indexed the new tx but we already
  /// know the asset deltas from the PSET. Cache is overwritten on
  /// the next successful `sync()`.
  Future<Either<ServiceFailure, Balance>> applyOptimisticBalanceDelta({
    required Map<String, int> deltas,
  });
}
