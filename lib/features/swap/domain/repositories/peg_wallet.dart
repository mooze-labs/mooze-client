import 'package:fpdart/fpdart.dart';

import '../entities/peg_error.dart';

class PegFundingQuote {
  const PegFundingQuote({
    required this.handle,
    required this.amountSat,
    required this.networkFeeSat,
  });

  final Object handle;

  /// What arrives at the deposit address, in satoshis.
  final BigInt amountSat;

  /// On-chain fee for the funding transaction. Separate from SideSwap's
  /// service fee, which comes from [PegServerLimits].
  final BigInt networkFeeSat;

  BigInt get totalSat => amountSat + networkFeeSat;
}

abstract class PegWallet {
  /// Liquid address to receive peg-in proceeds. Must come from LWK so the
  /// output is derivable from the same descriptor that holds the keys.
  TaskEither<PegError, String> getLiquidPayoutAddress();

  /// Bitcoin address to receive peg-out proceeds.
  TaskEither<PegError, String> getBitcoinPayoutAddress();
  TaskEither<PegError, PegFundingQuote> quoteBitcoinFunding({
    required String destination,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
  });

  /// Size a Liquid funding transaction without broadcasting.
  TaskEither<PegError, PegFundingQuote> quoteLiquidFunding({
    required String destination,
    required BigInt amountSat,
    double? feeRateSatPerVb,
    bool drain = false,
  });

  TaskEither<PegError, String> broadcastBitcoinFunding(PegFundingQuote quote);

  TaskEither<PegError, String> broadcastLiquidFunding(PegFundingQuote quote);
}
