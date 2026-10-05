import 'chain.dart';
import 'fee_estimate.dart';

/// Caller-supplied parameters for an on-chain send. The chain service is
/// responsible for selecting UTXOs / coins, building the transaction, and
/// surfacing the resulting [FeeEstimate] before broadcast — the user gets a
/// chance to review.
///
/// Lightning sends use [LightningSendRequest] instead.
class SendRequest {
  const SendRequest({
    required this.chain,
    required this.destination,
    required this.amountSat,
    this.assetId,
    this.feePriority = FeePriority.medium,
    this.label,
    this.subtractFeeFromAmount = false,
    this.feeRateOverrideSatPerVByte,
    this.drain = false,
  });

  final ChainId chain;

  /// On-chain address. Validation is the service's responsibility (network +
  /// confidential-vs-explicit for Liquid).
  final String destination;

  /// Amount in satoshis (or the asset's minimal units when [assetId] is set).
  /// Ignored by the service when [drain] is true.
  final int amountSat;

  /// Optional Liquid asset id. Null = L-BTC for Liquid, BTC for Bitcoin.
  final String? assetId;

  final FeePriority feePriority;
  final String? label;

  /// When true, the absolute fee is deducted from [amountSat] instead of being
  /// added on top — used for "send max" UX.
  final bool subtractFeeFromAmount;

  /// Power-user override. When set, the service uses this rate instead of the
  /// estimator's resolution for [feePriority]. Always sat/vB.
  final double? feeRateOverrideSatPerVByte;

  /// Drain semantics — service computes max-spendable for `assetId` (or chain
  /// native asset when null) and ignores [amountSat]. The fee is deducted from
  /// the drained amount the same way [subtractFeeFromAmount] does, but the
  /// amount itself is service-resolved rather than caller-supplied.
  final bool drain;
}

/// Caller-supplied parameters for a Lightning payment.
///
/// Only one of [bolt11] / [lnurl] / [nodeIdAndDestination] is used at a time.
/// The infra layer matches against whichever is set; ambiguity is rejected
/// with a [ServiceFailure] before any network round-trip.
class LightningSendRequest {
  const LightningSendRequest({
    this.bolt11,
    this.lnurl,
    this.lnAddress,
    this.amountSat,
    this.label,
  });

  /// BOLT-11 invoice. Authoritative — amount is encoded in the invoice unless
  /// it's a zero-amount one, in which case [amountSat] is required.
  final String? bolt11;

  /// LNURL-pay or LNURL-withdraw URL. The service drives the multi-step LNURL
  /// dance internally and returns a single [PreparedLightningSend].
  final String? lnurl;

  /// Lightning Address (RFC: name@domain.tld).
  final String? lnAddress;

  /// Required for zero-amount BOLT-11 / LNURL-pay; ignored otherwise.
  final int? amountSat;

  final String? label;
}

/// Output of `prepareSend()` for Lightning. The service has done the route-
/// probing and fee estimation; the caller receives a token they can hand back
/// to `send()`. Invariant: the prepared object is consumed exactly once.
class PreparedLightningSend {
  const PreparedLightningSend({
    required this.opaqueToken,
    required this.amountSat,
    required this.feeEstimate,
    this.destinationDescription,
  });

  /// Service-provided handle (typically a Breez SDK preparation result).
  /// Treat as an opaque blob; do NOT try to introspect.
  final Object opaqueToken;
  final int amountSat;
  final FeeEstimate feeEstimate;

  /// Human-readable description for the review screen ("paying foo@bar.com",
  /// "paying invoice to bc1q...", etc.).
  final String? destinationDescription;
}
