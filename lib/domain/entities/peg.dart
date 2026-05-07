// Peg-in (Bitcoin → L-BTC) and peg-out (L-BTC → Bitcoin) request/quote
// shapes. Peg operations are first-class balance transitions in the unified
// wallet domain — they cross the Bitcoin/Liquid boundary while staying
// inside the user's single sat-denominated balance.
//
// Lifecycle mirrors the rest of the V2 send surface: stateless `prepare`
// returns a quote, `execute` re-derives state from the canonical request.
// No opaque prepared objects round-trip through the UI.

class PegInRequest {
  const PegInRequest({
    required this.payerAmountSat,
    this.feeRateSatPerVByte,
    this.drain = false,
  });

  /// Amount the user wants to send into the peg, in satoshis. Ignored when
  /// [drain] is true (service computes max-spendable Bitcoin).
  final int payerAmountSat;

  /// Optional override for the on-chain Bitcoin fee rate (sat/vB). When null
  /// the service uses its default resolution for the configured priority.
  final double? feeRateSatPerVByte;

  /// Drain the entire spendable Bitcoin balance into the peg. Mutually
  /// exclusive with [payerAmountSat] in semantics — service ignores the
  /// amount field when true.
  final bool drain;
}

class PegInQuote {
  const PegInQuote({
    required this.bitcoinAddress,
    required this.payerAmountSat,
    required this.totalFeesSat,
    required this.breezFeesSat,
    required this.bdkFeesSat,
  });

  /// One-time on-chain Bitcoin address the user pays into. Owned by the
  /// Breez swap server; valid only for this peg-in.
  final String bitcoinAddress;

  /// Final amount the user is sending (post-drain resolution if drain=true).
  final int payerAmountSat;

  /// Sum of [breezFeesSat] + [bdkFeesSat] for review-screen display.
  final int totalFeesSat;

  /// Service fee charged by Breez for the swap.
  final int breezFeesSat;

  /// On-chain Bitcoin transaction fee.
  final int bdkFeesSat;
}

class PegOutRequest {
  const PegOutRequest({
    required this.btcAddress,
    required this.receiverAmountSat,
    this.feeRateSatPerVByte,
    this.drain = false,
  });

  /// Bitcoin destination address — where the user wants the BTC to land.
  final String btcAddress;

  /// Amount the user wants to receive on Bitcoin (NOT the L-BTC sent),
  /// in satoshis. Service computes the L-BTC debit by adding fees.
  /// Ignored when [drain] is true.
  final int receiverAmountSat;

  /// Optional override for the Bitcoin-side fee rate (sat/vB). Used by the
  /// swap engine to size the peg-out claim transaction.
  final double? feeRateSatPerVByte;

  /// Drain the entire L-BTC balance through the peg-out. Service computes
  /// the equivalent receiverAmountSat after fees.
  final bool drain;
}

class PegOutQuote {
  const PegOutQuote({
    required this.receiverAmountSat,
    required this.totalFeesSat,
  });

  /// Final BTC amount that will land at the destination.
  final int receiverAmountSat;

  /// Total swap + on-chain fees in satoshis (deducted from the L-BTC pool).
  final int totalFeesSat;
}
