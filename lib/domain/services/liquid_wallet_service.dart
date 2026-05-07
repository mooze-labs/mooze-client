import 'package:fpdart/fpdart.dart';

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
/// **Liquid sends through Breez vs LWK** — regular Liquid sends still
/// route through `LightningWalletService` (Breez-backed); LWK is
/// read-only EXCEPT for swap PSET signing. The split mirrors legacy
/// behavior: see V2_PHASE2_PARITY_AND_MIGRATION §G7 / Phase 2.5-Liquid.
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
}
